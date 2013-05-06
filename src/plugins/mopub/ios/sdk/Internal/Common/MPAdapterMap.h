//
//  MPAdapterMap.h
//  MoPub
//
//  Created by Andrew He on 1/26/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPAdapterMap : NSObject

/*
 * Get the shared adapter map.
 */
+ (id)sharedAdapterMap;

/*
 * Convenience methods for getting the Class representation for a certain ad network type.
 */
- (Class)bannerAdapterClassForNetworkType:(NSString *)networkType;
- (Class)interstitialAdapterClassForNetworkType:(NSString *)networkType;

@end
