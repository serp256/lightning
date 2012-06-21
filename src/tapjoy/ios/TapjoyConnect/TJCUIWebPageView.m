// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#import "TJCUIWebPageView.h"
#import "TJCLog.h"
#import "TJCConstants.h"
#import "TapjoyConnect.h"
#import "TJCLoadingView.h"
#import "TJCVideoManager.h"
#import "TJCVideoRequestHandler.h"

@implementation TJCUIWebPageView

@synthesize isViewVisible = isViewVisible_, loadingView = loadingView_, isAlertViewVisible = isAlertViewVisible_;


- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		cWebView_ = [[UIWebView alloc] initWithFrame:frame];
		
		[cWebView_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
		delegate_ = self;
		cWebView_.delegate = delegate_;
		[self addSubview:cWebView_];

		// Init loading view.
		if (loadingView_)
		{
			[loadingView_ release];
		}
		loadingView_ = [[TJCLoadingView alloc] initWithFrame:frame];
		[self addSubview: loadingView_.mainView];
		// This will make the loading view not visible.
		[loadingView_ disable];
		
		[self setViewToTransparent:YES];
	}
	
	return self;
}


- (void)refreshWithFrame:(CGRect)frame
{
	if (cWebView_)
	{
		[cWebView_ release];
	}
	cWebView_ = [[UIWebView alloc] initWithFrame:frame];
	[cWebView_ setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	cWebView_.delegate = delegate_;
	[self addSubview:cWebView_];
	
	// Init loading view.
	[[loadingView_ mainView] setFrame:frame];
	[self addSubview: loadingView_.mainView];
	// This will make the loading view not visible.
	[loadingView_ disable];
	
	[self setViewToTransparent:NO];
}


- (void)setViewToTransparent:(BOOL)transparent
{
	if (transparent)
	{
		[self setBackgroundColor:[UIColor clearColor]];
		[self setOpaque:NO];
		[cWebView_ setBackgroundColor:[UIColor clearColor]];
		[cWebView_ setOpaque:NO];
	}
	else 
	{
		[self setBackgroundColor:[UIColor whiteColor]];
		[self setOpaque:YES];
		[cWebView_ setBackgroundColor:[UIColor whiteColor]];
		[cWebView_ setOpaque:YES];
	}
}


- (void)clearWebViewContents
{
	if (cWebView_)
	{
		[cWebView_ release];
		cWebView_ = nil;
	}
}


- (void)parseVideoClickURL:(NSString*)videoClickURL shouldPlayVideo:(BOOL)shouldPlay
{
	NSString *requestStringTrimmed = [videoClickURL stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_PROTOCOL_COMPLETE withString:@""];
	NSArray *parts = [requestStringTrimmed componentsSeparatedByString:@"&"];
	NSString *offerID = nil;
	NSString *clickURL = nil;
	NSString *videoCompleteURL = nil;
	NSString *currencyName = nil;
	NSString *currencyAmount = nil;
	
	for (NSString *part in parts)
	{
		if (CFStringFind((CFStringRef)part, (CFStringRef)TJC_VIDEO_CLICK_ID, kCFCompareCaseInsensitive).length > 0)
		{
			// Video ID found, trim off the paramater portion.
			// NOTE: Creating a temporary string seems to fix a memory leak problem.
			offerID = [NSString stringWithString:[part stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_ID withString:@""]];
			
			continue;
		}
		
		if (CFStringFind((CFStringRef)part, (CFStringRef)TJC_VIDEO_CLICK_URL, kCFCompareCaseInsensitive).length > 0)
		{
			// Click URL found, trim off the parameter portion.
			clickURL = [part stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_URL withString:@""];
			
			continue;
		}
		
		if (CFStringFind((CFStringRef)part, (CFStringRef)TJC_VIDEO_CLICK_COMPLETE_URL, kCFCompareCaseInsensitive).length > 0)
		{
			// Video Complete URL found, trim off the parameter portion.
			videoCompleteURL = [part stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_COMPLETE_URL withString:@""];
			
			continue;
		}
				
		if (CFStringFind((CFStringRef)part, (CFStringRef)TJC_VIDEO_CLICK_CURRENCY_AMOUNT, kCFCompareCaseInsensitive).length > 0)
		{
			// Currency amount found, trim off parameter portion.
			currencyAmount = [part stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_CURRENCY_AMOUNT withString:@""];
			
			continue;
		}
		
		if (CFStringFind((CFStringRef)part, (CFStringRef)TJC_VIDEO_CLICK_CURRENCY_NAME, kCFCompareCaseInsensitive).length > 0)
		{
			// Currency name found, trim off parameter portion.
			currencyName = [part stringByReplacingOccurrencesOfString:TJC_VIDEO_CLICK_CURRENCY_NAME withString:@""];
			currencyName = [currencyName stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
			
			continue;
		}
	}
	
	// All parts should be set. If not, set error message.
	if (!offerID)
	{
		[TJCLog logWithLevel:LOG_NONFATAL_ERROR format:@"Error: Video Offer ID not set"];
		return;
	}
	
	if (!clickURL)
	{
		[TJCLog logWithLevel:LOG_NONFATAL_ERROR format:@"Error: Video Offer click URL not set"];
		return;
	}
	
	if (!videoCompleteURL)
	{
		[TJCLog logWithLevel:LOG_NONFATAL_ERROR format:@"Error: Video Complete URL not set"];
		return;
	}
	
	if (!currencyName)
	{
		currencyName = @"currency";
	}
	
	if (!currencyAmount)
	{
		currencyAmount = @"some";
	}
	
	// Ping server for video click.
	[[[TJCVideoManager sharedTJCVideoManager] requestHandler] recordVideoClickWithURL:clickURL];
	// Save off updated currency amount and name.
	NSDictionary *allVideosDict = [[TJCVideoManager sharedTJCVideoManager] getAllVideosDictionary];
	NSMutableDictionary* videoObjDict = [NSMutableDictionary dictionaryWithDictionary:[allVideosDict objectForKey:offerID]];
	[videoObjDict setObject:currencyName forKey:TJC_VIDEO_OBJ_CURRENCY_NAME];
	[videoObjDict setObject:currencyAmount forKey:TJC_VIDEO_OBJ_CURRENCY_AMOUNT];
	[videoObjDict setObject:videoCompleteURL forKey:TJC_VIDEO_OBJ_COMPLETE_URL];
	[[TJCVideoManager sharedTJCVideoManager] setAllVideosObjectDict:videoObjDict withKey:offerID];
	
	if (shouldPlay)
	{
		// Get video id (offer id) and initiate video play.
		[TapjoyConnect showVideoAdWithOfferID:offerID];
	}
}


- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType 
{	
	// If we see either tapjoy or linkshare host names, we won't open it externally. All other host names will open externally from the app.
	if ((CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_TAPJOY_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_TAPJOY_ALT_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_LINKSHARE_HOST_NAME, kCFCompareCaseInsensitive).length > 0))
	{
		return YES;
	}
	
	// Open the link externally.
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[request URL]] 
																			  delegate:self 
																	startImmediately:YES];
	[conn release];
	return NO;
}


- (NSString*)appendGenericParamsWithURL:(NSString*)theURL
{
	NSString *result = [NSString stringWithFormat:@"%@%@", 
							  theURL, 
							  [TapjoyConnect createQueryStringFromDict:[[TapjoyConnect sharedTapjoyConnect] genericParameters]]];
	
	return result;
}


- (void)loadURLRequest:(NSString*)requestURLString withTimeOutInterval:(int)tInterval
{
	[TJCLog logWithLevel:LOG_DEBUG format:@"Request URL: %@", requestURLString];
	
	NSURL *requestURL = [NSURL URLWithString:requestURLString];
	
	lastClickedURL_ = requestURLString;
	
	[cWebView_ stopLoading];
	
	NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:requestURL
																				cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
																		  timeoutInterval:tInterval];
	[cWebView_ loadRequest:myRequest];
}


- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse 
{
	// Returning nil will ensure that no cached response will be stored for the connection.
	// This is in case the cache is being used by something else.
	return nil;
}


- (void)webViewDidStartLoad:(UIWebView*)webView
{
	[loadingView_ fadeIn];
}


- (void)webViewDidFinishLoad:(UIWebView*)webView
{
	[loadingView_ fadeOut];
}


- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
	if (error.code == NSURLErrorCancelled) return; //error 999 fast clicked the links
	
	[TJCLog logWithLevel:LOG_DEBUG format:@"ERROR TEXT IS %@",[error description]];
	
	// sum bug solved in 4.0 need to confirm
	if (error.code == 102) 
		return;
	
	if (isViewVisible_)
	{
		UIAlertView * alertview = [[UIAlertView alloc] initWithTitle:@"" 
																			  message:TJC_GENERIC_CONNECTION_ERROR_MESSAGE 
																			 delegate:self 
																 cancelButtonTitle:@"Cancel" 
																 otherButtonTitles:@"Retry", nil];
		[alertview show];
		[alertview release];
		isAlertViewVisible_ = YES;
	}
}


- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[TJCLog logWithLevel:LOG_DEBUG format:@"TJC CUSTOM WEB Page View Alert Click Called (Net Error Case)"];
	
	if (buttonIndex == 1)
	{
		[self loadURLRequest:lastClickedURL_ withTimeOutInterval:TJC_REQUEST_TIME_OUT];
	}
	
	isAlertViewVisible_ = NO;
}


- (void)setDelegate:(id)delegate
{
	delegate_ = delegate;
	cWebView_.delegate = delegate_;
}


- (void)dealloc
{
	[cWebView_ release];
	[loadingView_ release];
	[super dealloc];
}


@end
