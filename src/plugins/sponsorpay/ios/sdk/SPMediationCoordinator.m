//
//  SPMediationCoordinator.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 5/16/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPMediationCoordinator.h"
#import "SPTPNManager.h"
#import "SPTPNGenericAdapter.h"
#import "SPTPNManager.h"
#import "SPLogger.h"

@interface SPMediationCoordinator ()

@property (strong) NSDictionary *providersByName;

@end

@implementation SPMediationCoordinator

- (id<SPTPNVideoAdapter>)providerWithName:(NSString *)name
{
    return [SPTPNManager getRewardedVideoAdapterForNetwork:name];
}

- (BOOL)providerAvailable:(NSString *)providerKey
{
    return [SPTPNManager getRewardedVideoAdapterForNetwork:providerKey] != nil;
}

- (void)videosFromProvider:(NSString *)providerKey available:(SPTPNValidationResultBlock)callback;
{
    id provider = [self providerWithName:providerKey];

    SPLogInfo(@"Provider %@ integrated: %@", providerKey, provider ? @"YES" : @"NO");

    if (!provider) {
        callback(providerKey, SPTPNValidationNoSdkIntegrated);
        return;
    }

    [provider videosAvailable:callback];
}

-(void)playVideoFromProvider:(NSString *)providerKey eventsCallback:(SPTPNVideoEventsHandlerBlock)eventsCallback
{
    SPLogInfo(@"Playing video from %@", providerKey);

    id provider = [self providerWithName:providerKey];

    if (!provider) {
        eventsCallback(providerKey, SPTPNVideoEventNoSdk);
        return;
    }

    // TODO could self.hostViewController be nil?
    [provider playVideoWithParentViewController:self.hostViewController
                              notifyingCallback:eventsCallback];
    self.hostViewController = nil;
}

@end
