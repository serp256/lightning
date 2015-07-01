//
//  SPTPNVideoAdapter.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 5/17/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPTPNMediationTypes.h"
#import "SPBaseNetwork.h"

@protocol SPTPNVideoAdapter<NSObject>

- (void)setNetwork:(SPBaseNetwork *)network;
- (NSString *)networkName;
- (void)videosAvailable:(SPTPNValidationResultBlock)callback;
- (void)playVideoWithParentViewController:(UIViewController *)parentVC notifyingCallback:(SPTPNVideoEventsHandlerBlock)eventsCallback;

- (BOOL)startAdapterWithDictionary:(NSDictionary *)dict;

@end

typedef NS_ENUM(NSInteger, SPTPNProviderPlayingState) {
    SPTPNProviderPlayingStateNotPlaying,
    SPTPNProviderPlayingStateWaitingForPlayStart,
    SPTPNProviderPlayingStatePlaying
};