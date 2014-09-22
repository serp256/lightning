//
//  SPConstants.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 08/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPConstants : NSObject

// mBE Constants
FOUNDATION_EXPORT NSString *const SPVideoHideRewardNotification;

// Interstitial Event Notification constants
FOUNDATION_EXPORT NSString *const SPInterstitialEventNotification;
FOUNDATION_EXPORT NSString *const SPInterstitialEventURL;

FOUNDATION_EXPORT NSString *const SPUrlGeneratorRequestIDKey;

// Exceptions names
FOUNDATION_EXPORT NSString *const SPInvalidUserIdException;

// MBE Constants
FOUNDATION_EXPORT NSString *const SPRequestValidate;
FOUNDATION_EXPORT NSString *const SPTPNIDParameter;

@end
