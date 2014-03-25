//
//  SPProviderAppLovin.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 09/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPAppLovinNetwork.h"
#import "SPTPNGenericAdapter.h"
#import "SPInterstitialNetworkAdapter.h"
#import "SPRewardedVideoNetworkAdapter.h"
#import "SPLogger.h"
#import "ALSdk.h"

static NSString *const SPAppLovinSDKKey = @"SPAppLovinSdkKey";

static NSString *const SPInterstitialAdapterClassName = @"SPAppLovinInterstitialAdapter";
static NSString *const SPRewardedVideoAdapterClassName = @"SPAppLovinRewardedVideoAdapter";

@interface SPAppLovinNetwork()
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign, readwrite) SPNetworkSupport supportedServices;
@property (nonatomic, copy) NSString *apiKey;

@property (nonatomic, strong) SPTPNGenericAdapter *rewardedVideoAdapter;
@property (nonatomic, strong) id<SPInterstitialNetworkAdapter> interstitialAdapter;

@end

@implementation SPAppLovinNetwork

@synthesize name;
@synthesize supportedServices;
@synthesize rewardedVideoAdapter;
@synthesize interstitialAdapter;

- (instancetype)init
{
    self = [super init];
    if (self) {
        Class RewardedVideoAdapterClass = NSClassFromString(SPRewardedVideoAdapterClassName);
        if (RewardedVideoAdapterClass) {
            self.rewardedVideoAdapter = [[SPTPNGenericAdapter alloc] init];
        }

        Class InterstitialAdapterClass = NSClassFromString(SPInterstitialAdapterClassName);
        if (InterstitialAdapterClass) {
            self.interstitialAdapter = [[InterstitialAdapterClass alloc] init];
        }
    }
    return self;
}

- (BOOL)startSDK:(NSDictionary *)data
{
    NSString *apiKey = data[SPAppLovinSDKKey];

    if (!apiKey.length) {
        SPLogError(@"Could not start %@ Provider. %@ empty or missing.", self.name, SPAppLovinSDKKey);
        return NO;
    }

    self.apiKey = data[SPAppLovinSDKKey];
    return YES;
}

- (void)startRewardedVideoAdapter:(NSDictionary *)data
{
    Class RewardedVideoAdapterClass = NSClassFromString(SPRewardedVideoAdapterClassName);
    if (!RewardedVideoAdapterClass) {
        return;
    }

    id<SPRewardedVideoNetworkAdapter> appLovinRewardedVideoAdapter = [[RewardedVideoAdapterClass alloc] init];

    SPTPNGenericAdapter *appLovinRewardedVideoAdapterWrapper = [[SPTPNGenericAdapter alloc] initWithVideoNetworkAdapter:appLovinRewardedVideoAdapter];
    appLovinRewardedVideoAdapter.delegate = appLovinRewardedVideoAdapterWrapper;

    self.rewardedVideoAdapter = appLovinRewardedVideoAdapterWrapper;

    [super startRewardedVideoAdapter:data];
}

@end
