//
//  SPTPNMediationTypes.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 6/13/13.
// Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPTPNValidationResult) {
    SPTPNValidationNoVideoAvailable,
    SPTPNValidationNoSdkIntegrated,
    SPTPNValidationTimeout,
    SPTPNValidationNetworkError,
    SPTPNValidationDiskError,
    SPTPNValidationError,
    SPTPNValidationSuccess
};

NSString *SPTPNValidationResultToString(SPTPNValidationResult validationResult);

typedef NS_ENUM(NSInteger, SPTPNVideoEvent) {
    SPTPNVideoEventStarted,
    SPTPNVideoEventAborted,
    SPTPNVideoEventFinished,
    SPTPNVideoEventClosed,
    SPTPNVideoEventNoVideo,
    SPTPNVideoEventTimeout,
    SPTPNVideoEventNoSdk,
    SPTPNVideoEventError
};

NSString *SPTPNVideoEventToString(SPTPNVideoEvent event);

typedef void (^SPTPNValidationResultBlock)(NSString *tpnKey, SPTPNValidationResult validationResult);
typedef void (^SPTPNVideoEventsHandlerBlock)(NSString *tpnKey, SPTPNVideoEvent event);
