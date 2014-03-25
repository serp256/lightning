//
//  ALAdRewardDelegate.h
//  sdk
//
//  Created by Matt Szaro on 1/3/14.
//
//

#import <Foundation/Foundation.h>
#import "ALAd.h"

#define kALErrorCodeUnknownServerError -400
#define kALErrorCodeServerTimeout -500
#define kALErrorCodeUserClosedVideo -600

@protocol ALAdRewardDelegate <NSObject>

/*
* If you are using reward validation for incentivized videos, this method
* will be invoked if we contacted AppLovin successfully. This means that we believe the
* reward is legitimate and should be awarded. Please note that ideally you should refresh the
* user's balance from your server at this point to prevent tampering with local data on jailbroken devices.
*/
-(void) rewardValidationRequestForAd: (ALAd*) ad didSucceedWithResponse: (NSDictionary*) response;

/*
 * This method will be invoked if we were able to contact AppLovin, but the user has already received
 * the maximum number of coins you allowed per day in the web UI.
 */
-(void) rewardValidationRequestForAd: (ALAd*) ad didExceedQuotaWithResponse: (NSDictionary*) response;

/*
 * This method will be invoked if the AppLovin server rejected the reward request.
 * This would usually happen if the user fails to pass an anti-fraud check.
 */
-(void) rewardValidationRequestForAd: (ALAd *) ad wasRejectedWithResponse: (NSDictionary*) response;

/*
 * This method will be invoked if were unable to contact AppLovin, so no ping will be heading to your server.
 */
-(void) rewardValidationRequestForAd: (ALAd*) ad didFailWithError: (NSInteger) responseCode;

/*
 * This method will be invoked if the user chooses 'no' when asked if they want to view a rewarded video.
 */
-(void) userDeclinedToViewAd: (ALAd*) ad;

@end
