//
//  SPProvider.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 15/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPLogger.h"
#import "SPBaseNetwork.h"
#import "SPTPNGenericAdapter.h"

static NSString *const SPProviderData = @"SPProviderData";

@interface SPBaseNetwork()

@property (nonatomic, assign, readwrite) SPNetworkSupport supportedServices;
@property (nonatomic, strong, readwrite) id<SPTPNVideoAdapter> rewardedVideoAdapter;
@property (nonatomic, strong, readwrite) id<SPInterstitialNetworkAdapter> interstitialAdapter;
@property (nonatomic, copy, readwrite) NSString *name;

@end

@implementation SPBaseNetwork

+ (SPSemanticVersion *)adapterVersion
{
    [NSException raise:NSInternalInconsistencyException format:@"%@", [NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]];
    return nil;
}

- (BOOL)startNetworkWithName:(NSString *)networkName data:(NSDictionary *)data
{
    SPLogInfo(@"Starting SDK and mediation adapters for %@", networkName);
    self.name = networkName;
    BOOL sdkStarted = [self startSDK:data];
    if (!sdkStarted) {
        SPLogError(@"Could not start SDK for %@", networkName);
        return NO;
    }

    [self startRewardedVideoAdapter:data];
    [self startInterstitialAdapter:data];
    return YES;
}

- (BOOL)startSDK:(NSDictionary *)data
{
    NSString *exceptionReason = [NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    [NSException raise:NSInternalInconsistencyException format:@"%@", exceptionReason];

    return NO;
}

- (void)startRewardedVideoAdapter:(NSDictionary *)data
{
    [self.rewardedVideoAdapter setNetwork:self];
    BOOL videoAdapterStarted = [self.rewardedVideoAdapter startAdapterWithDictionary:data];

    if (!videoAdapterStarted) {
        self.rewardedVideoAdapter = nil;
        return;
    }
    self.supportedServices = self.supportedServices | SPNetworkSupportRewardedVideo;
}

- (void)startInterstitialAdapter:(NSDictionary *)data
{
    [self.interstitialAdapter setNetwork:self];
    BOOL interstitialAdapterStarted = [self.interstitialAdapter startAdapterWithDict:data];

    if (!interstitialAdapterStarted) {
        self.interstitialAdapter = nil;
        return;
    }

    self.supportedServices = self.supportedServices | SPNetworkSupportInterstitial;
}
@end
