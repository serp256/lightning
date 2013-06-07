//
//  SPAdvertiserManager.h
//  SponsorPay iOS SDK
//
//  Copyright 2011 SponsorPay. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SPPersistence.h"

/**
 * Singleton for reporting offers to the SponsorPay server.
 */
@interface SPAdvertiserManager : NSObject

/**
 * Retrieves the shared singleton instance of this class.
 */
+ (SPAdvertiserManager*)sharedManager __deprecated;

+ (SPAdvertiserManager *)advertiserManagerForAppId:(NSString *)appId;


/**
 * Sends a message to the SponsorPay server telling it that the app has been run.
 * This should be invoked on startup (every time) in case it fails to access the network--
 * in such cases it will retry, but only if it hasn't yet succeeded.
 */
- (void)reportOfferCompleted:(NSString *)appId __deprecated;

- (void)reportOfferCompleted;

- (void)reportActionCompleted:(NSString *)actionId;

+ (void)overrideBaseURLWithURLString:(NSString *)newURLString;
+ (void)restoreBaseURLToDefault;

@end
