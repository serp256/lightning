//
//  SPTPNVideoAdapter.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 5/17/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPTPNMediationTypes.h"
#import <UIKit/UIKit.h>
#import "SPBaseNetwork.h"

#define SPTPNTimeoutInterval ((NSTimeInterval)4.5)

@class SPBaseNetwork;

@protocol SPTPNVideoAdapter <NSObject>

- (void)setNetwork:(SPBaseNetwork *)network;
- (NSString *)networkName;
- (void)videosAvailable:(SPTPNValidationResultBlock)callback;
- (void)playVideoWithParentViewController:(UIViewController *)parentVC
                        notifyingCallback:(SPTPNVideoEventsHandlerBlock)eventsCallback;

- (BOOL)startAdapterWithDictionary:(NSDictionary *)dict;

@end

typedef enum {
    SPTPNProviderPlayingStateNotPlaying,
    SPTPNProviderPlayingStateWaitingForPlayStart,
    SPTPNProviderPlayingStatePlaying

} SPTPNProviderPlayingState;