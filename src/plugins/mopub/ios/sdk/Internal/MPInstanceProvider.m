//
//  MPInstanceProvider.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPInstanceProvider.h"
#import "MPAdWebView.h"
#import "MPAdDestinationDisplayAgent.h"
#import "MPURLResolver.h"
#import "MPAdWebViewAgent.h"
#import "MPInterstitialAdManager.h"
#import "MPAdServerCommunicator.h"
#import "MPAdapterMap.h"
#import "MPInterstitialCustomEventAdapter.h"
#import "MPLegacyInterstitialCustomEventAdapter.h"
#import "MPHTMLInterstitialViewController.h"
#import "MPAnalyticsTracker.h"
#import "MPGlobal.h"
#import "MPMRAIDInterstitialViewController.h"

@implementation MPInstanceProvider

static MPInstanceProvider *sharedProvider = nil;

+ (MPInstanceProvider *)sharedProvider
{
    if (!sharedProvider) {
        sharedProvider = [[MPInstanceProvider alloc] init];
    }
    return sharedProvider;
}

- (MPAnalyticsTracker *)buildMPAnalyticsTracker
{
    return [MPAnalyticsTracker trackerWithUserAgentString:MPUserAgentString()];
}

- (MPAdWebViewAgent *)buildMPAdWebViewAgentWithAdWebViewFrame:(CGRect)frame delegate:(id<MPAdWebViewAgentDelegate>)delegate customMethodDelegate:(id)customMethodDelegate
{
    return [[[MPAdWebViewAgent alloc] initWithAdWebViewFrame:frame delegate:delegate customMethodDelegate:customMethodDelegate] autorelease];
}

- (MPAdWebView *)buildMPAdWebViewWithFrame:(CGRect)frame delegate:(id<UIWebViewDelegate>)delegate
{
    MPAdWebView *webView = [[[MPAdWebView alloc] initWithFrame:frame] autorelease];
    webView.delegate = delegate;
    return webView;
}

- (MPAdDestinationDisplayAgent *)buildMPAdDestinationDisplayAgentWithDelegate:(id<MPAdDestinationDisplayAgentDelegate>)delegate
{
    return [MPAdDestinationDisplayAgent agentWithDelegate:delegate];
}

- (MPURLResolver *)buildMPURLResolver
{
    return [MPURLResolver resolver];
}

- (MPInterstitialAdManager *)buildMPInterstitialAdManagerWithDelegate:(id<MPInterstitialAdManagerDelegate>)delegate
{
    return [[[MPInterstitialAdManager alloc] initWithDelegate:delegate] autorelease];
}

- (MPAdServerCommunicator *)buildMPAdServerCommunicatorWithDelegate:(id<MPAdServerCommunicatorDelegate>)delegate
{
    return [[[MPAdServerCommunicator alloc] initWithDelegate:delegate] autorelease];
}

- (MPBaseInterstitialAdapter *)buildInterstitialAdapterForConfiguration:(MPAdConfiguration *)configuration
                                                               delegate:(id<MPBaseInterstitialAdapterDelegate>)delegate
{
    if ([configuration.networkType isEqualToString:@"custom"]) {
        if (configuration.customEventClass) {
            return [[[MPInterstitialCustomEventAdapter alloc] initWithDelegate:delegate] autorelease];
        } else if (configuration.customSelectorName) {
            return [[[MPLegacyInterstitialCustomEventAdapter alloc] initWithDelegate:delegate] autorelease];
        } else {
            return nil;
        }
    } else {
        Class adapterClass = [[MPAdapterMap sharedAdapterMap] interstitialAdapterClassForNetworkType:configuration.networkType];
        return [[(MPBaseInterstitialAdapter *)[adapterClass alloc] initWithDelegate:delegate] autorelease];
    }
}

- (MPHTMLInterstitialViewController *)buildMPHTMLInterstitialViewControllerWithDelegate:(id<MPHTMLInterstitialViewControllerDelegate>)delegate
                                                                        orientationType:(MPInterstitialOrientationType)type
                                                                   customMethodDelegate:(id)customMethodDelegate
{
    MPHTMLInterstitialViewController *controller = [[[MPHTMLInterstitialViewController alloc] init] autorelease];
    controller.delegate = delegate;
    controller.orientationType = type;
    controller.customMethodDelegate = customMethodDelegate;
    return controller;
}

- (MPMRAIDInterstitialViewController *)buildMPMRAIDInterstitialViewControllerWithDelegate:(id<MPMRAIDInterstitialViewControllerDelegate>)delegate
                                                                            configuration:(MPAdConfiguration *)configuration
{
    MPMRAIDInterstitialViewController *controller = [[[MPMRAIDInterstitialViewController alloc] initWithAdConfiguration:configuration] autorelease];
    controller.delegate = delegate;
    return controller;
}

@end

