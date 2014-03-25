//
//  ALIncentivizedInterstitialAd.h
//  sdk
//
//  Created by Matt Szaro on 10/1/13.
//
//

#import <Foundation/Foundation.h>
#import "ALInterstitialAd.h"
#import "ALAdVideoPlaybackDelegate.h"
#import "ALAdDisplayDelegate.h"
#import "ALAdLoadDelegate.h"
#import "ALAdRewardDelegate.h"

#define kALErrorCodeIncentiviziedAdNotPreloaded -300

/*
 ALIncentivizedInterstitialAd is intended to help you provide incentivized videos to your user.
 
 This class will always return video interstitials, and will notify your ALAdVideoPlaybackDelegate
 about how much of the video the user viewed. Based on this information you are free to provide
 the user with virutal currency, game upgrades, or whatever else you choose.
 
 This does not apply to standard, non-incentivized placements; in those cases, you should
 use the standard ALInterstitialAd class, which is automatically pre-cached for you.
 */

@interface ALIncentivizedInterstitialAd : NSObject

/**
 * You may optionally set an Ad Display Delegate to be notified when the ad appears and disappears.
 */
@property (strong, nonatomic) id<ALAdDisplayDelegate> adDisplayDelegate;

/**
 * You may optionally set an Ad Video Playback Delegate to be notified when the video begins and ends.
 */
@property (strong, nonatomic) id<ALAdVideoPlaybackDelegate> adVideoPlaybackDelegate;

/**
 * Get a reference to the shared instance of ALIncentivizedInterstitialAd.
 * This wraps the [ALSdk shared] call, and will only work if you hve set your SDK key in Info.plist.
*/
+(ALIncentivizedInterstitialAd*) shared;

/**
 * Pre-load an incentivized interstitial, and notify your provided Ad Load Delegate.
 * This method uses the shared instance, and will only work if you have set your SDK key in Info.plist.
 *
 * @param adLoadDelegate The delegate to notify that preloading was completed.
 */
+(void) preloadAndNotify: (id<ALAdLoadDelegate>) adLoadDelegate;

/**
 * Show an incentivized interstitial, using the most recently pre-loaded ad.
 * You must call preloadAndNotify before calling showOver.
 *
 * @param adRewardValidationDelegate The reward delegate to notify upon validating reward authenticity with AppLovin.
 *
 * Using the ALAdRewardDelegate, you will be able to verify with AppLovin servers the the video view is legitimate,
 * as we will confirm whether the specific ad was actually served - then we will ping your server with a url for you to update
 * the user's balance. The Reward Validation Delegate will tell you whether we were able to reach our servers or not. If you receive
 * a successful response, you should refresh the user's balance from your server. For more info, see the documentation.
 */
+(void) showOver: (UIWindow*) window andNotify: (id<ALAdRewardDelegate>) adRewardDelegate;

/**
 * Initialize an incentivized interstitial with a specific custom SDK.
 * This is necessary if you use [ALSdk sharedWithKey: ...].
 *
 * @param An SDK instance to use.
 */
-(instancetype) initIncentivizedInterstitialWithSdk: (ALSdk*) anSdk;

/**
 * Pre-load an incentivized interstitial, and notify your provided Ad Load Delegate.
 *
 * @param adLoadDelegate The delegate to notify that preloading was completed.
 */
-(void) preloadAndNotify: (id<ALAdLoadDelegate>) adLoadDelegate;

/**
 * Show an incentivized interstitial, using the most recently pre-loaded ad.
 * You must call preloadAndNotify before calling showOver.
 *
 * @param adRewardValidationDelegate The reward delegate to notify upon validating reward authenticity with AppLovin.
 *
 * Using the ALAdRewardDelegate, you will be able to verify with AppLovin servers the the video view is legitimate,
 * as we will confirm whether the specific ad was actually served - then we will ping your server with a url for you to update
 * the user's balance. The Reward Validation Delegate will tell you whether we were able to reach our servers or not. If you receive
 * a successful response, you should refresh the user's balance from your server. For more info, see the documentation.
 */
-(void) showOver: (UIWindow*) window andNotify: (id<ALAdRewardDelegate>) adRewardDelegate;

/**
 * Dismiss an incentivized interstitial prematurely, before video playback has completed.
 * In most circumstances, this is not recommended, as it may confuse users by denying them a reward.
 */
-(void) dismiss;

/**
 * If you're using reward validation, you can optionally set a user identifier to be included with
 * currency validation postbacks. For example, a user name. We'll include this in the postback when we
 * ping your currency endpoint from our server.
 */
+(void) setUserIdentifier: (NSString*) userIdentifier;
+(NSString*) userIdentifier;

@end
