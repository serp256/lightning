//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import "FYBInterstitialNetworkAdapter.h"
#import "FYBTPNMediationTypes.h"
#import "FYBPrecachingNetworkAdapter.h"


@protocol FYBTPNVideoAdapter;
@class FYBAdapterOptions;


typedef NS_OPTIONS(NSUInteger, FYBNetworkSupport) {
    FYBNetworkSupportNone,
    FYBNetworkSupportRewardedVideo,
    FYBNetworkSupportInterstitial
};


/**
 Abstract Class for provider
 This class provides common functionality between all networks, such as initializing the underlying SDKs, instantiating the suitable adapters, and to store information about the supported services
 */
@interface FYBBaseNetwork : NSObject

/** The ad formats that are supported by this network */
@property (nonatomic, assign, readonly) FYBNetworkSupport supportedServices;

/** The rewarded video adapter to be used to access a network */
@property (nonatomic, strong, readonly) id<FYBTPNVideoAdapter> rewardedVideoAdapter;

/** The interstitial adapter to be used to access a network */
@property (nonatomic, strong, readonly) id<FYBInterstitialNetworkAdapter> interstitialAdapter;

/** The name of the network */
@property (nonatomic, copy, readonly) NSString *name;

/**
* The API version that the SDK will use for compatibility check
*/
+ (NSUInteger)apiVersion;

/**
* A human readable version of the adapter bundle.
*/
+ (NSString *)bundleVersion;

- (BOOL)startNetwork:(NSString *)networkName options:(FYBAdapterOptions *)adapterOptions;

- (BOOL)startWithOptions:(FYBAdapterOptions *)options;
- (void)startInterstitialAdapter:(NSDictionary *)data;
- (void)startRewardedVideoAdapter:(NSDictionary *)data;

@end
