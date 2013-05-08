//
//  MPInstanceProvider.h
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPInterstitialViewController.h"

@class MPAdWebViewAgent;
@class MPAdWebView;
@class MPAdDestinationDisplayAgent;
@class MPURLResolver;
@class MPInterstitialAdManager;
@class MPAdServerCommunicator;
@class MPBaseInterstitialAdapter;
@class MPAdConfiguration;
@class MPHTMLInterstitialViewController;
@class MPAnalyticsTracker;
@class MPMRAIDInterstitialViewController;

@protocol MPAdWebViewAgentDelegate;
@protocol MPAdDestinationDisplayAgentDelegate;
@protocol MPInterstitialAdManagerDelegate;
@protocol MPAdServerCommunicatorDelegate;
@protocol MPBaseInterstitialAdapterDelegate;
@protocol MPHTMLInterstitialViewControllerDelegate;
@protocol MPMRAIDInterstitialViewControllerDelegate;

@interface MPInstanceProvider : NSObject

+ (MPInstanceProvider *)sharedProvider;

- (MPAnalyticsTracker *)buildMPAnalyticsTracker;

- (MPAdWebViewAgent *)buildMPAdWebViewAgentWithAdWebViewFrame:(CGRect)frame
                                                     delegate:(id<MPAdWebViewAgentDelegate>)delegate
                                         customMethodDelegate:(id)customMethodDelegate;
- (MPAdWebView *)buildMPAdWebViewWithFrame:(CGRect)frame
                                  delegate:(id<UIWebViewDelegate>)delegate;
- (MPAdDestinationDisplayAgent *)buildMPAdDestinationDisplayAgentWithDelegate:(id<MPAdDestinationDisplayAgentDelegate>)delegate;
- (MPURLResolver *)buildMPURLResolver;
- (MPInterstitialAdManager *)buildMPInterstitialAdManagerWithDelegate:(id<MPInterstitialAdManagerDelegate>)delegate;
- (MPAdServerCommunicator *)buildMPAdServerCommunicatorWithDelegate:(id<MPAdServerCommunicatorDelegate>)delegate;
- (MPBaseInterstitialAdapter *)buildInterstitialAdapterForConfiguration:(MPAdConfiguration *)configuration
                                                               delegate:(id<MPBaseInterstitialAdapterDelegate>)delegate;
- (MPHTMLInterstitialViewController *)buildMPHTMLInterstitialViewControllerWithDelegate:(id<MPHTMLInterstitialViewControllerDelegate>)delegate
                                                                        orientationType:(MPInterstitialOrientationType)type
                                                                   customMethodDelegate:(id)customMethodDelegate;
- (MPMRAIDInterstitialViewController *)buildMPMRAIDInterstitialViewControllerWithDelegate:(id<MPMRAIDInterstitialViewControllerDelegate>)delegate
                                                                            configuration:(MPAdConfiguration *)configuration;

@end
