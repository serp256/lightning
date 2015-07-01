//
//  SponsorPay iOS SDK
//
//  Created by Daniel Barden on 15/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPInterstitialNetworkAdapter.h"
#import "SPTPNMediationTypes.h"


@protocol SPTPNVideoAdapter;

typedef NS_OPTIONS(NSUInteger, SPNetworkSupport) {
    SPNetworkSupportNone,
    SPNetworkSupportRewardedVideo,
    SPNetworkSupportInterstitial
};

@class SPSemanticVersion;
@protocol SPTPNVideoAdapter;

/**
 Abstract Class for provider.
 This class provides common functionality between all the Networks, such as initialize the underlying SDKs, instantiate the suitable adapters and store information about the supported services.
 */
@interface SPBaseNetwork : NSObject

/** The ad formats that are supported by this network */
@property (nonatomic, assign, readonly) SPNetworkSupport supportedServices;

/** The rewarded video adapter to be used to access a network */
@property (nonatomic, strong, readonly) id<SPTPNVideoAdapter> rewardedVideoAdapter;

/** The interstitial adapter to be used to access a network */
@property (nonatomic, strong, readonly) id<SPInterstitialNetworkAdapter> interstitialAdapter;

/** The name of the network */
@property (nonatomic, copy, readonly) NSString *name;

+ (SPSemanticVersion *)adapterVersion;

- (BOOL)startNetworkWithName:(NSString *)networkName data:(NSDictionary *)data;

- (BOOL)startSDK:(NSDictionary *)data;
- (void)startInterstitialAdapter:(NSDictionary *)data;
- (void)startRewardedVideoAdapter:(NSDictionary *)data;

@end
