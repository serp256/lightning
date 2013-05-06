//
//  MPHTMLInterstitialAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPHTMLInterstitialAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInterstitialAdController.h"
#import "MPLogging.h"
#import "MPInstanceProvider.h"

@interface MPHTMLInterstitialAdapter ()

@property (nonatomic, retain) MPHTMLInterstitialViewController *interstitial;

@end

@implementation MPHTMLInterstitialAdapter

@synthesize interstitial = _interstitial;

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    MPLogTrace(@"Loading HTML interstitial with source: %@", [configuration adResponseHTMLString]);

    self.interstitial = [[MPInstanceProvider sharedProvider] buildMPHTMLInterstitialViewControllerWithDelegate:self
                                                                                               orientationType:configuration.orientationType
                                                                                          customMethodDelegate:[self.delegate interstitialDelegate]];
    [self.interstitial loadConfiguration:configuration];
}

- (void)dealloc
{
    [self.interstitial setDelegate:nil];
    [self.interstitial setCustomMethodDelegate:nil];
    self.interstitial = nil;
    [super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [self.interstitial presentInterstitialFromViewController:controller];
}

#pragma mark - MPHTMLInterstitialViewControllerDelegate

- (void)interstitialDidLoadAd:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate adapterDidFinishLoadingAd:self];
}

- (void)interstitialDidFailToLoadAd:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate adapter:self didFailToLoadAdWithError:nil];
}

- (void)interstitialWillAppear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate interstitialWillAppearForAdapter:self];
}

- (void)interstitialDidAppear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate interstitialDidAppearForAdapter:self];
    [self trackImpression];
}

- (void)interstitialWillDisappear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate interstitialWillDisappearForAdapter:self];
}

- (void)interstitialDidDisappear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate interstitialDidDisappearForAdapter:self];
}

- (void)interstitialWillLeaveApplication:(MPHTMLInterstitialViewController *)interstitial
{
    [self.delegate interstitialWillLeaveApplicationForAdapter:self];
}

@end
