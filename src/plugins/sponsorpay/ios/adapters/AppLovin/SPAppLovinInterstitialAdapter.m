//
//  SPAppLovingInterstitialAdapter.m
//  SponsorPayTestApp
//
//  Created by David Davila on 01/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPAppLovinInterstitialAdapter.h"
#import "SPAppLovinNetwork.h"
#import "ALInterstitialAd.h"
#import "SPLogger.h"

#define LogInvocation NSLog(@"%s", __PRETTY_FUNCTION__);

NSString *const SPAppLovinSDKAppKey = @"SPAppLovinSDKAppKey";

@interface SPAppLovinInterstitialAdapter() {
    BOOL _adWasClicked;
}

@property (weak, nonatomic) id<SPInterstitialNetworkAdapterDelegate> delegate;
@property (strong, nonatomic) NSDictionary *parameters;

@property (strong, nonatomic) ALSdk *appLovinSDKInstance;
@property (strong, nonatomic) id lastLoadedAd;

@end

@implementation SPAppLovinInterstitialAdapter


- (NSString *)appKey
{
    return self.parameters[SPAppLovinSDKAppKey];
}

- (NSString *)networkName
{
    return [self.network name];
}

- (BOOL)startAdapterWithDict:(NSDictionary *)dict
{
    ALSdkSettings *alSDKSettings = [[ALSdkSettings alloc] init];
    alSDKSettings.isVerboseLogging = NO;

    self.appLovinSDKInstance = [ALSdk sharedWithKey:self.network.apiKey settings:alSDKSettings];
    [self cacheInterstitial];

    return YES;
}

- (void)cacheInterstitial
{
    self.lastLoadedAd = nil;

    id adService = [self.appLovinSDKInstance adService];
    [adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:self];
}

- (BOOL)canShowInterstitial
{
    if (!self.lastLoadedAd) {
        // seems like there's some interest on this adapter. Try again at least for next time.
        [self cacheInterstitial];
    }

    return self.lastLoadedAd != nil;
}

- (void)showInterstitialFromViewController:(UIViewController *)viewController
{
    _adWasClicked = NO;

    id interstitialAd = [[ALInterstitialAd alloc] initInterstitialAdWithSdk:self.appLovinSDKInstance];
    [interstitialAd setAdDisplayDelegate:self];
    UIWindow *window = viewController.view.window;
    [interstitialAd showOver:window andRender:self.lastLoadedAd];
}

#pragma mark - ALAdLoadDelegate

- (void)adService:(id)adService didLoadAd:(id)ad
{
    LogInvocation
    self.lastLoadedAd = ad;
}

- (void)adService:(id)adService didFailToLoadAdWithError:(int)code
{
    NSError *error = [NSError errorWithDomain:@"com.sponsorpay.interstitialError" code:code userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"AppLift returned code %d", code]}];
    [self.delegate adapter:self didFailWithError:error];
}

#pragma mark - ALAdDisplayDelegate

- (void)ad:(id)ad wasDisplayedIn:(id)view
{
    LogInvocation
    [self.delegate adapterDidShowInterstitial:self];
}

- (void)ad:(id)ad wasClickedIn:(id)view
{
    LogInvocation
    _adWasClicked = YES;
}

- (void)ad:(id)ad wasHiddenIn:(id)view
{
    LogInvocation

    SPInterstitialDismissReason reason = _adWasClicked ?
    SPInterstitialDismissReasonUserClickedOnAd : SPInterstitialDismissReasonUserClosedAd;

    [self.delegate adapter:self didDismissInterstitialWithReason:reason];

    [self cacheInterstitial];
}

@end
