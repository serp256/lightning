//
//  SPApplifierAdapter.h
//  SponsorPaySample
//
//  Created by David Davila on 10/1/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPRewardedVideoNetworkAdapter.h"


#import <ApplifierImpact/ApplifierImpact.h>

@class SPApplifierNetwork;
//#define APPLIFIER_TEST_MODE

@interface SPApplifierRewardedVideoAdapter : NSObject <SPRewardedVideoNetworkAdapter, ApplifierImpactDelegate>

@property (nonatomic, weak) SPApplifierNetwork *network;

@end