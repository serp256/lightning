// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#import "TJCOffersWebView.h"
#import "TJCConstants.h"
#import "TJCUINavigationBarView.h"
#import "TapjoyConnect.h"
#import "TJCLog.h"
#import "TJCUtil.h"
#import "TJCViewCommons.h"
#import "TJCLoadingView.h"
#import "TJCVideoManager.h"
#import "TJCVideoRequestHandler.h"
#import "TJCVideoViewHandler.h"

static NSString *currentServiceURL = nil;


@implementation TJCOffersWebView



@synthesize parentVController_, currencyID_, isSelectorVisible_;
@synthesize navBar = navBar_;


- (id)init
{
	// Init frame here in case access to local variables is needed. For instance, if a custom bg image is set before the view is actually shown.
	self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
	
	if (self)
	{
		[self refreshWithFrame:[[UIScreen mainScreen] bounds] enableNavBar:YES];
	}
	
	return self;
}

- (id)initWithFrame:(CGRect)frame enableNavBar:(BOOL)enableNavigationBar
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self refreshWithFrame:frame enableNavBar:enableNavigationBar];
	}
	
	return self;
}


- (void)refreshWithFrame:(CGRect)frame enableNavBar:(BOOL)enableNavigationBar
{	
	[self clearWebViewContents];
	[super refreshWithFrame:frame];
	
	[self setFrame:frame];
	[loadingView_.mainView setFrame:frame];
	
	cWebView_.scalesPageToFit = TRUE;
	cWebView_.autoresizesSubviews = YES;
	// Touch is not yet enabled for the webview and will not be until the page has loaded.
	[cWebView_ setUserInteractionEnabled:NO];
	
	if(enableNavigationBar)
	{
		if (!navBar_)
		{
			navBar_ = [[TJCUINavigationBarView alloc] initWithTitle:@"" withFrame:frame AtY:0];
			
			[navBar_ setNavBarLeftBtnWithTitle:@"Back"];
			[navBar_ addLeftButtonTarget:self action:@selector(backtoGameAction:) forControlEvents:UIControlEventTouchUpInside];
		}
		
		[self addSubview:navBar_];
	}
	else
	{
		if (navBar_)
		{
			[navBar_ removeFromSuperview];
		}
	}
	
	enableNavBar = enableNavigationBar;
	
	[self setViewToTransparent:NO];
}


- (void)setCustomNavBarImage:(UIImage*)image
{
	[navBar_ setCustomBackgroundImage:image];
}


- (NSString*)setUpOffersURLWithServiceURL:(NSString*)serviceURL
{
	NSString *result = [self appendGenericParamsWithURL:serviceURL];

	NSString *userID = [TapjoyConnect getUserID];
	
	if (userID)
	{
		result = [NSString stringWithFormat:
					 @"%@&%@=%@",
					 result,
					 TJC_URL_PARAM_USER_ID,
					 [TapjoyConnect createQueryStringFromString:userID]];
	}
	
	if (currencyID_ && [currencyID_ length] > 0)
	{
		result = [NSString stringWithFormat:@"%@&%@", result, currencyID_];
	}
	
	if (isSelectorVisible_ && [isSelectorVisible_ length] > 0)
	{
		result = [NSString stringWithFormat:@"%@&%@", result, isSelectorVisible_];
	}
	
	// Only display videos if the flag is set.
	if ([TJCVideoManager sharedTJCVideoManager].shouldShowVideos)
	{
		NSString *connectionType = [TJCNetReachability getReachibilityType];
		if ([connectionType isEqualToString:@"wifi"])
		{
			// Enable streaming for wifi connections. This will display all available videos on the offer wall.
			result = [NSString stringWithFormat:@"%@&%@", result, TJC_URL_PARAM_WIFI_VIDEOS];
		}
		else
		{
			// Send cached videos to the offer wall.
			NSDictionary *cachedVideoDict = [[TJCVideoManager sharedTJCVideoManager] getCachedVideoDictonary];
			if ([cachedVideoDict count] > 0)
			{
				NSMutableString *videoIDString = [[NSMutableString alloc] initWithFormat:@"%@=", TJC_URL_PARAM_VIDEO_IDS];
				
				// Add video ids.
				for (NSDictionary *videoObjKey in cachedVideoDict)
				{
					NSDictionary *videoObjDict = [cachedVideoDict objectForKey:videoObjKey];
					[videoIDString appendFormat:@"%@,", [videoObjDict objectForKey:TJC_VIDEO_OBJ_OFFER_ID]];
				}
				[videoIDString deleteCharactersInRange:NSMakeRange([videoIDString length] - 1, 1)];
				
				result = [NSString stringWithFormat:@"%@&%@", result, videoIDString];
				
				[videoIDString release];
			}
		}
	}
	
	return result;
}


- (void)loadViewWithURL:(NSString*)URLString
{
	if (!URLString)
	{
		currentServiceURL = [self setUpOffersURLWithServiceURL:
									[NSString stringWithFormat:@"%@%@?", TJC_SERVICE_URL, TJC_WEB_OFFERS_URL_NAME]];
	}
	else 
	{
		currentServiceURL = URLString;
	}
	
	//initialize WebView UI
	int shiftVal = 0;
	
	// Set the shift amount depending on whether there is a navigation bar or not.
	if (enableNavBar)
	{
		shiftVal = TJC_NAV_BAR_HEIGHT;
	}
	
	if (parentVController_)
	{
		[navBar_ setFrame:CGRectMake(navBar_.frame.origin.x, navBar_.frame.origin.y, parentVController_.view.bounds.size.width, navBar_.frame.size.height)];
		[cWebView_ setFrame:CGRectMake(0, shiftVal, parentVController_.view.bounds.size.width, parentVController_.view.bounds.size.height - shiftVal)];
	}
	else
	{
		[navBar_ setFrame:CGRectMake(navBar_.frame.origin.x, navBar_.frame.origin.y, self.bounds.size.width, navBar_.frame.size.height)];
		[cWebView_ setFrame:CGRectMake(0, shiftVal, self.bounds.size.width, self.bounds.size.height - shiftVal)];
	}
	
	[self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	
	[self loadURLRequest:currentServiceURL withTimeOutInterval:TJC_REQUEST_TIME_OUT];
}



- (void)refreshWebView
{
	NSString *offersURL = [self setUpOffersURLWithServiceURL:
								  [NSString stringWithFormat:@"%@%@?", TJC_SERVICE_URL, TJC_WEB_OFFERS_URL_NAME]];
	
	[self loadURLRequest:offersURL withTimeOutInterval:TJC_REQUEST_TIME_OUT];
}



#pragma mark OverRidden Connection Methods

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
	if (error.code == NSURLErrorCancelled) 
	{
		return; //error 999 fast clicked the links
	}
	
	// 102 error code for slow request completion. This happens when a NSURLConnection is made for opening links externally in Safari.
	if (error.code == 102) 
	{
		return;
	}
	
	// Something failed with the default URL, try the alternate one.
	if (currentServiceURL == [NSString stringWithFormat:@"%@%@?", TJC_SERVICE_URL, TJC_WEB_OFFERS_URL_NAME])
	{
		currentServiceURL = [self setUpOffersURLWithServiceURL:
									[NSString stringWithFormat:@"%@%@?", TJC_SERVICE_URL_ALTERNATE, TJC_WEB_OFFERS_URL_NAME]];		
		[self loadViewWithURL:currentServiceURL];
	}
	else
	{
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
		
		//Stop Activity Indicator
		[loadingView_ fadeOut];
		
		// Disable user touch interaction.
		[webView setUserInteractionEnabled:NO];
	}
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// The retry button action.
	if(buttonIndex == 1)
	{
		[loadingView_ fadeIn];
		[cWebView_ stopLoading];
		
		[self loadViewWithURL:nil]; 
	}
	// The cancel button action.
	else if(buttonIndex == 0) 
	{
		//Stop Activity Indicator
		[loadingView_ fadeOut];
		
		// Re-enable user touch interaction so that they may click on another link to try again if so desired.
		[cWebView_ setUserInteractionEnabled:YES];
	}
	
	isAlertViewVisible_ = NO;
}


- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	//NSLog(@"URL host: %@", [[request URL] host]);
	
	if (!request)
	{
		return NO;
	}
	
	// Check for video click.
	NSString *requestString = [[request URL] absoluteString];
	NSString *requestHost = [[request URL] host];
	if (requestString == nil)
	{
		// Error check. If the request string is null for some reason, do nothing.
		return NO;
	}
	else if (CFStringFind((CFStringRef)requestString, (CFStringRef)TJC_VIDEO_CLICK_PROTOCOL, kCFCompareCaseInsensitive).length > 0)
	{
		[self parseVideoClickURL:requestString shouldPlayVideo:YES];
		
		// Handled, return NO.
		return NO;
	}
	// If we see either tapjoy or linkshare host names, we won't open it externally. All other host names will open externally from the app.
	else if ((CFStringFind((CFStringRef)requestHost, (CFStringRef)TJC_TAPJOY_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)requestHost, (CFStringRef)TJC_TAPJOY_ALT_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)requestHost, (CFStringRef)TJC_LINKSHARE_HOST_NAME, kCFCompareCaseInsensitive).length > 0))
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


- (void)webViewDidStartLoad:(UIWebView *)webView
{
	isViewVisible_ = YES;
	
	[loadingView_ fadeIn];	
	
	// Disable user touch interaction.
	[webView setUserInteractionEnabled:NO];
	
	[[[navBar_ navBarTitle] titleView] setAlpha:0.0f];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[loadingView_ fadeOut];
	
	// Re-enable user touch interaction.
	[webView setUserInteractionEnabled:YES];
	
	// Pull the title for the Offers view from the html title tag.
	[[navBar_ navBarTitle] setTitle:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
	
	// Make it fade in smoothly.
	[[navBar_ navBarTitle] titleView].alpha = 0.0f;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25];
	[[navBar_ navBarTitle] titleView].alpha = 1.0f;
	[UIView commitAnimations];	
}


- (NSURLRequest*)connection:(NSURLConnection*)connection 
				willSendRequest:(NSURLRequest*)request 
			  redirectResponse:(NSURLResponse*)response
{
	[TJCLog logWithLevel:LOG_DEBUG format:@"OPENING EXTERNAL URL NOW ::::::%@", [request URL]];
	
	[loadingView_ fadeOut];
	
	// Open up itunes. This will effectively place this app in the background.
	[[UIApplication sharedApplication] openURL:[request URL]];
	
	// Immediately cancel redirects since we only care about the first one.
	[connection cancel];
	
	// Returning nil will also ensure that we don't follow the redirects within the webview.
	// We rely on mobile safari to do so.
	return nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	// If the view has been dismissed, then don't open the link.
	if (!isViewVisible_)
	{
		[connection cancel];
	}
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (isViewVisible_)
	{
		UIAlertView * alertview = [[UIAlertView alloc] initWithTitle:@"" 
																			  message:TJC_GENERIC_CONNECTION_ERROR_MESSAGE
																			 delegate:self 
																 cancelButtonTitle:@"Cancel" 
																 otherButtonTitles:@"Retry", nil];
		[alertview show];
		[alertview release];
	}
	
	//Stop Activity Indicator
	[loadingView_ fadeOut];
	
	// Disable user touch interaction.
	[cWebView_ setUserInteractionEnabled:NO];
}


- (void)backtoGameAction:(id)sender
{
	[TJCViewCommons animateTJCView:self 
					 withTJCTransition:[[TJCViewCommons sharedTJCViewCommons]getReverseTransitionEffect] 
								withDelay:[[TJCViewCommons sharedTJCViewCommons]getTransitionDelay]];
	
	[self performSelector:@selector(giveBackNotification) 
				  withObject:nil 
				  afterDelay:[[TJCViewCommons sharedTJCViewCommons]getTransitionDelay]];
}


- (void)giveBackNotification
{	
	isViewVisible_ = NO;
	
	// Clear web view contents.
	[self clearWebViewContents];
	
	[self removeFromSuperview];
	
	// Remove any transforms applied to this view.
	self.transform = CGAffineTransformIdentity;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TJC_VIEW_CLOSED_NOTIFICATION object:nil];
	
	// JC: NOTE: Deprecated since 8.1.0
	[[NSNotificationCenter defaultCenter] postNotificationName:TJC_SHOW_BOX_CLOSE_NOTIFICATION object:nil];
	
	[TapjoyConnect clearCache];
	
	// This will notify the offers view handler to release the web view.
	[[NSNotificationCenter defaultCenter] postNotificationName:TJC_OFFERWALL_WEBVIEW_CLOSE_NOTIFICATION object:nil];
}


- (void)dealloc 
{
	[TJCLog logWithLevel:LOG_DEBUG format:@"TJCOffersView Dealloc"];
	[navBar_ release];
	[super dealloc];
}


@end