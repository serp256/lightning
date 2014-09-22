//
//  SPConstants.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 08/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPConstants.h"

@implementation SPConstants

// mBE Constants
NSString *const SPVideoHideRewardNotification = @"SPVideoHideRewardNotification";

// Interstitial Event Notification constants
NSString *const SPInterstitialEventNotification = @"SPInterstitialEventNotification";
NSString *const SPInterstitialEventURL = @"http://engine.sponsorpay.com/tracker";

// Url Generator Constants
NSString *const SPUrlGeneratorRequestIDKey = @"request_id";

// Exceptions Names

NSString *const SPInvalidUserIdException = @"SPInvalidUserIdException";

// MBE Constants
NSString *const SPRequestValidate = @"validate";
NSString *const SPTPNIDParameter = @"id";
@end

