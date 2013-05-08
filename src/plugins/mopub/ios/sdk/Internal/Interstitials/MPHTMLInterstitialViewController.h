//
//  MPHTMLInterstitialViewController.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MPAdWebViewAgent.h"
#import "MPInterstitialViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPHTMLInterstitialViewControllerDelegate;
@class MPAdConfiguration;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPHTMLInterstitialViewController : MPInterstitialViewController <MPAdWebViewAgentDelegate>

@property (nonatomic, assign) id<MPHTMLInterstitialViewControllerDelegate> delegate;
@property (nonatomic, retain) MPAdWebViewAgent *backingViewAgent;
@property (nonatomic, assign) id customMethodDelegate;

- (void)loadConfiguration:(MPAdConfiguration *)configuration;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPHTMLInterstitialViewControllerDelegate <NSObject>

- (void)interstitialDidLoadAd:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidFailToLoadAd:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillAppear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidAppear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillDisappear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidDisappear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillLeaveApplication:(MPHTMLInterstitialViewController *)interstitial;

@end
