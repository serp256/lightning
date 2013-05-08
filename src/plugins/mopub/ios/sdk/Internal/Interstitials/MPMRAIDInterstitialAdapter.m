//
//  MPMraidInterstitialAdapter.m
//  MoPub
//
//  Created by Andrew He on 12/11/11.
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPMraidInterstitialAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInstanceProvider.h"
#import "MPInterstitialAdController.h"
#import "MPInterstitialAdManager.h"
#import "MPLogging.h"

@interface MPMRAIDInterstitialAdapter ()

@property (nonatomic, retain) MPMRAIDInterstitialViewController *interstitial;

@end

@implementation MPMRAIDInterstitialAdapter

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    self.interstitial = [[MPInstanceProvider sharedProvider] buildMPMRAIDInterstitialViewControllerWithDelegate:self
                                                                                                  configuration:configuration];
    [self.interstitial setCloseButtonStyle:MPInterstitialCloseButtonStyleAdControlled];
    [self.interstitial startLoading];
}

- (void)dealloc
{
    self.interstitial.delegate = nil;
    self.interstitial = nil;

    [super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self.interstitial presentInterstitialFromViewController:controller];
}

#pragma mark - MPMRAIDInterstitialViewControllerDelegate

- (void)interstitialDidLoadAd:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate adapterDidFinishLoadingAd:self];
}

- (void)interstitialDidFailToLoadAd:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)interstitialWillAppear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate interstitialWillAppearForAdapter:self];
}

- (void)interstitialDidAppear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate interstitialDidAppearForAdapter:self];
    [self trackImpression];
}

- (void)interstitialWillDisappear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate interstitialWillDisappearForAdapter:self];
}

- (void)interstitialDidDisappear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.delegate interstitialDidDisappearForAdapter:self];
}

@end
