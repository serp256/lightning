// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import "TJCFeaturedAppViewHandler.h"
#import "TJCFeaturedAppView.h"
#import "SynthesizeSingleton.h"
#import "TJCFeaturedAppManager.h"
#import "TJCLog.h"



@implementation TJCFeaturedAppViewHandler

@synthesize featuredAppView = featuredAppView_;

TJC_SYNTHESIZE_SINGLETON_FOR_CLASS(TJCFeaturedAppViewHandler)


- (id)init
{
	self = [super init];

	if (self)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:TJC_FEATURED_WEBVIEW_CLOSE_NOTIFICATION object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
															  selector:@selector(removeFeaturedWebView) 
																	name:TJC_FEATURED_WEBVIEW_CLOSE_NOTIFICATION
																 object:nil];
	}

	return self;
}


- (void)dealloc
{
	[featuredAppView_ release];
	[super dealloc];
}


- (void)removeFeaturedWebView
{
	if ([[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView])
	{
		[[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView] removeFromSuperview];
		[[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView] release];
		[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler].featuredAppView = nil;
	}
}


+ (UIView*)showFullScreenAdWithURL:(NSString*)adURL
{
	return [self showFullScreenAdWithURL:adURL withFrame:[[UIScreen mainScreen] bounds]];
}


+ (UIView*)showFullScreenAdWithURL:(NSString *)adURL withFrame:(CGRect)frame
{
	[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] removeFeaturedWebView];
	[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler].featuredAppView = [[TJCFeaturedAppView alloc] initWithFrame:frame];

	[[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView] loadViewWithURL:adURL];
	
	[TJCViewCommons animateTJCView:[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView]
					 withTJCTransition:[[TJCViewCommons sharedTJCViewCommons] getCurrentTransitionEffect] 
								withDelay:[[TJCViewCommons sharedTJCViewCommons] getTransitionDelay]];
	
	return [[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView];
}


+ (void)showFullScreenAdWithURL:(NSString*)adURL withViewController:(UIViewController*)vController
{
	if(!vController || ![vController isKindOfClass:[UIViewController class]])
	{
		NSAssert(NO,@"View Controller provided must not be nil or some other object");
	}
	
	[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] removeFeaturedWebView];
	[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler].featuredAppView = [[TJCFeaturedAppView alloc] initWithFrame:vController.view.bounds];

	[[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView] loadViewWithURL:adURL];
	
	[vController.view addSubview:[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView]];
	
	[TJCViewCommons animateTJCView:[[TJCFeaturedAppViewHandler sharedTJCFeaturedAppViewHandler] featuredAppView]
					 withTJCTransition:[[TJCViewCommons sharedTJCViewCommons] getCurrentTransitionEffect] 
								withDelay:[[TJCViewCommons sharedTJCViewCommons] getTransitionDelay]];
	
}


@end



@implementation TapjoyConnect (TJCFeaturedAppViewHandler)

+ (void)getFeaturedApp
{
	[[TJCFeaturedAppManager sharedTJCFeaturedAppManager] getFeaturedApp];
}


+ (void)getFeaturedAppWithCurrencyID:(NSString*)currencyID
{
	[[TJCFeaturedAppManager sharedTJCFeaturedAppManager] getFeaturedAppWithCurrencyID:currencyID];
}


+ (UIView*)showFeaturedAppFullScreenAd
{
	if ([[TJCFeaturedAppManager sharedTJCFeaturedAppManager] featuredAppModelObj])
	{
		return [[TJCCallsWrapper sharedTJCCallsWrapper] showFeaturedAppFullScreenAdWithURL:
				  [[TJCFeaturedAppManager sharedTJCFeaturedAppManager] featuredAppModelObj].fullScreenAdURL];
	}
	else
	{
		[TJCLog logWithLevel:LOG_NONFATAL_ERROR format:@"There was an error getting the full screen ad URL. Was getFeaturedApp called?"];
	}
	
	return nil;
}


+ (UIView*)showFeaturedAppFullScreenAdWithFrame:(CGRect)frame
{
	if ([[TJCFeaturedAppManager sharedTJCFeaturedAppManager] featuredAppModelObj])
	{
		return [[TJCCallsWrapper sharedTJCCallsWrapper] showFeaturedAppFullScreenAd: [[TJCFeaturedAppManager sharedTJCFeaturedAppManager] featuredAppModelObj].fullScreenAdURL
																								withFrame: frame];
	}
	else
	{
		[TJCLog logWithLevel:LOG_NONFATAL_ERROR format:@"There was an error getting the full screen ad URL. Was getFeaturedApp called?"];
	}
	
	return nil;
}


+ (void)showFeaturedAppFullScreenAdWithViewController:(UIViewController*)vController
{
	[[TJCCallsWrapper sharedTJCCallsWrapper] showFeaturedAppFullScreenAd: 
	 [[TJCFeaturedAppManager sharedTJCFeaturedAppManager] featuredAppModelObj].fullScreenAdURL
																	  withViewController:vController];
}


+ (void)setFeaturedAppDisplayCount:(int) displayCount
{
	[[TJCFeaturedAppManager sharedTJCFeaturedAppManager] setFeaturedAppDisplayCount:displayCount];
}


+ (void)setFeaturedAppDelayCount:(int)delayCount
{
	[[TJCFeaturedAppManager sharedTJCFeaturedAppManager] setFeaturedAppDelayCount:delayCount];
}


@end


@implementation TJCCallsWrapper (TJCFeaturedAppViewHandler)

- (UIView*)showFeaturedAppFullScreenAdWithURL:(NSString*)adURL
{
	return [self showFeaturedAppFullScreenAd:adURL withFrame:self.view.bounds];
}


- (UIView*)showFeaturedAppFullScreenAd:(NSString*)adURL withFrame:(CGRect)frame
{
	UIView *fullScreenAdView = nil;
	
	[self moveViewToFront];
	
	[self.view setAlpha:1];
	
	fullScreenAdView = [TJCFeaturedAppViewHandler showFullScreenAdWithURL:adURL withFrame:frame];
	[self.view addSubview:fullScreenAdView];
	
	return fullScreenAdView;
}


- (void)showFeaturedAppFullScreenAd:(NSString*)adURL withViewController:(UIViewController*)vController
{
	[self.view setAlpha: 0];
	
	[TJCFeaturedAppViewHandler showFullScreenAdWithURL:adURL withViewController:vController];
}

@end