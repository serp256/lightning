//
//  SPApplifierProvider.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 13/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPApplifierNetwork.h"
#import "SPApplifierRewardedVideoAdapter.h"
#import "SPLogger.h"
#import "SPTPNGenericAdapter.h"
#import <ApplifierImpact/ApplifierImpact.h>
#import "SPApplifierRewardedVideoAdapter.h"

static NSString *const SPApplifierGameId = @"SPApplifierGameId";

@interface SPApplifierNetwork()

@property (nonatomic, strong) SPTPNGenericAdapter *rewardedVideoAdapter;

@end

@implementation SPApplifierNetwork

@synthesize rewardedVideoAdapter;

- (BOOL)startSDK:(NSDictionary *)data
{
    NSString *gameId = data[SPApplifierGameId];

    if (!gameId) {
        SPLogError(@"Could not start %@ Provider. %@ empty or missing.", self.name, SPApplifierGameId);
        return NO;
    }
    
    [[ApplifierImpact sharedInstance] startWithGameId:gameId];
    return YES;
}

- (void)startRewardedVideoAdapter:(NSDictionary *)data
{
    SPApplifierRewardedVideoAdapter *applifierAdapter = [[SPApplifierRewardedVideoAdapter alloc] init];

    SPTPNGenericAdapter *applifierAdapterWrapper = [[SPTPNGenericAdapter alloc] initWithVideoNetworkAdapter:applifierAdapter];
    applifierAdapter.delegate = applifierAdapterWrapper;

    self.rewardedVideoAdapter = applifierAdapterWrapper;

    [super startRewardedVideoAdapter:data];
}

@end
