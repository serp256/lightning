//
//  SPApplovinAdapter.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 06/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPRewardedVideoNetworkAdapter.h"

@class SPAppLovinNetwork;

@interface SPAppLovinRewardedVideoAdapter : NSObject <SPRewardedVideoNetworkAdapter>

@property (nonatomic, weak) SPAppLovinNetwork *network;

@end
