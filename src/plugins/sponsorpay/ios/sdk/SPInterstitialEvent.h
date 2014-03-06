//
//  SPInterstitialEvent.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPUrlParametersProvider.h"

/** Available Interstitials event types */
typedef NS_ENUM(NSUInteger, SPInterstitialEventType) {
    SPInterstitialEventTypeRequest,
    SPInterstitialEventTypeFill,
    SPInterstitialEventTypeNoFill,
    SPInterstitialEventTypeImpression,
    SPInterstitialEventTypeClick,
    SPInterstitialEventTypeClose,
    SPInterstitialEventTypeError
};

/**
 * Represents an interstitial event.
 * Stores an event of type SPInterstitialEventType and the network responsible for firing the event
 */
@interface SPInterstitialEvent : NSObject <SPURLParametersProvider>

@property (nonatomic, copy) NSString *network;
@property (nonatomic, assign) SPInterstitialEventType type;
@property (nonatomic, copy) NSString *adId;
@property (nonatomic, copy) NSString *requestId;

// The following are hardcoded values for the non rewarded interstitial in the iOS SDK. If we start using them across more ad formats we may want to extract them to their own parameters provider
@property (nonatomic, readonly) NSString *platform;
@property (nonatomic, readonly) NSString *adFormat;
@property (nonatomic, readonly) NSString *client;
@property (nonatomic, readonly) BOOL rewarded;

- (id)initWithEventType:(SPInterstitialEventType)eventType
                network:(NSString *)network
                   adId:(NSString *)adId
              requestId:(NSString *)requestId;

@end
