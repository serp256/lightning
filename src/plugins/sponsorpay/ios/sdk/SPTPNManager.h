//
//  SPProviderManager.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 30/12/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SPTPNVideoAdapter;
@protocol SPInterstitialNetworkAdapter;

/**
 Stores the registered Providers

 Stores the registered providers and provides accessibility methods to access the underlying adapters
 */
@interface SPTPNManager : NSObject

/**
 Starts and register the available providers

 The available providers are fetched by reading the entry "SPProviders" in the main plist file of the project. It also starts, when available,
 the video and interstitial adapters.
 */
+ (void)startNetworks;

/**
 Returns the video adapter for a given provider or nil.
 */
+ (id<SPTPNVideoAdapter>)getRewardedVideoAdapterForNetwork:(NSString *)networkName;

/**
 Returns all the video adapters available.
 */
+ (NSArray *)getAllRewardedVideoAdapters;

/**
 Returns the interstitial adapter for a given provider or nil.
 */
+ (id<SPInterstitialNetworkAdapter>)getInterstitialAdapterForNetwork:(NSString *)networkName;

/**
 Returns all the interstitial adapters available.
 */
+ (NSArray *)getAllInterstitialAdapters;

@end
