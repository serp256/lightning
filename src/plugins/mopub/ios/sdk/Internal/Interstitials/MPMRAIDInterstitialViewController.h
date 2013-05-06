//
//  MPMRAIDInterstitialViewController.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialViewController.h"

#import "MRAdView.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPMRAIDInterstitialViewControllerDelegate;
@class MPAdConfiguration;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPMRAIDInterstitialViewController : MPInterstitialViewController <MRAdViewDelegate>
{
    id<MPMRAIDInterstitialViewControllerDelegate> _delegate;
    MRAdView *_interstitialView;
    MPAdConfiguration *_configuration;
    BOOL _advertisementHasCustomCloseButton;
}

@property (nonatomic, assign) id<MPMRAIDInterstitialViewControllerDelegate> delegate;

- (id)initWithAdConfiguration:(MPAdConfiguration *)configuration;
- (void)startLoading;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPMRAIDInterstitialViewControllerDelegate <NSObject>

- (void)interstitialDidLoadAd:(MPMRAIDInterstitialViewController *)interstitial;
- (void)interstitialDidFailToLoadAd:(MPMRAIDInterstitialViewController *)interstitial;
- (void)interstitialWillAppear:(MPMRAIDInterstitialViewController *)interstitial;
- (void)interstitialDidAppear:(MPMRAIDInterstitialViewController *)interstitial;
- (void)interstitialWillDisappear:(MPMRAIDInterstitialViewController *)interstitial;
- (void)interstitialDidDisappear:(MPMRAIDInterstitialViewController *)interstitial;

@end
