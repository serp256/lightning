//
//  SPInterstitialEvent.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialEvent.h"
#import "SPConstants.h"

static NSString *const SPUrlGeneratorEventKey        = @"event";
static NSString *const SPUrlGeneratorAdIdKey         = @"ad_id";
static NSString *const SPUrlGeneratorProviderTypeKey = @"provider_type";
static NSString *const SPUrlGeneratorPlatformKey     = @"platform";
static NSString *const SPUrlGeneratorAdFormatKey     = @"ad_format";
static NSString *const SPUrlGeneratorClientKey       = @"client";
static NSString *const SPUrlGeneratorRewardedKey     = @"rewarded";

static NSString *const EventTypeToString[] = {
    [SPInterstitialEventTypeRequest]    = @"request",
    [SPInterstitialEventTypeFill]       = @"fill",
    [SPInterstitialEventTypeNoFill]     = @"no_fill",
    [SPInterstitialEventTypeImpression] = @"impression",
    [SPInterstitialEventTypeClick]      = @"click",
    [SPInterstitialEventTypeClose]      = @"close",
    [SPInterstitialEventTypeError]      = @"error",
    [SPInterstitialEventTypeNoSDK]      = @"no_sdk",
};

@implementation SPInterstitialEvent


- (id)initWithEventType:(SPInterstitialEventType)eventType
                network:(NSString *)network
                   adId:(NSString *)adId
              requestId:(NSString *)requestId
{
    self = [super init];
    if (self) {
        self.type = eventType;
        self.network = network;
        self.adId = adId;
        self.requestId = requestId;
    }
    return self;
}

// Maps the event type to event name
- (NSString *)typeToString
{
    return EventTypeToString[self.type];
}

- (NSDictionary *)dictionaryWithKeyValueParameters
{
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
    paramDict[SPUrlGeneratorEventKey] = [self typeToString];
    paramDict[SPUrlGeneratorRequestIDKey] = self.requestId;
    paramDict[SPUrlGeneratorPlatformKey] = self.platform;
    paramDict[SPUrlGeneratorAdFormatKey] = self.adFormat;
    paramDict[SPUrlGeneratorClientKey] = self.client;
    paramDict[SPUrlGeneratorRewardedKey] = [NSNumber numberWithBool:self.rewarded];

    if (self.adId) {
        paramDict[SPUrlGeneratorAdIdKey] = self.adId;
    }

    if (self.network.length) {
        paramDict[SPUrlGeneratorProviderTypeKey] = self.network;
    }
    return [NSDictionary dictionaryWithDictionary:paramDict];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"SPInterstitial event type: %@, provider: %@ adId: %@ requestId: %@", EventTypeToString[self.type], self.network, self.adId, self.requestId];
}

#pragma mark - Hardcoded values

- (NSString *)platform
{
    return @"ios";
}

- (NSString *)adFormat
{
    return @"interstitial";
}

- (NSString *)client
{
    return @"sdk";
}

- (BOOL)rewarded
{
    return NO;
}

@end
