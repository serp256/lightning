//
//  ALInterstitialAd.h
//
//  Created by Matt Szaro on 8/1/13.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "ALSdk.h"
#import "ALAdService.h"

@interface ALInterstitialAd : UIView

@property (strong, atomic) id<ALAdLoadDelegate> adLoadDelegate;
@property (strong, atomic) id<ALAdDisplayDelegate> adDisplayDelegate;
@property (strong, atomic) id<ALAdVideoPlaybackDelegate> adVideoPlaybackDelegate;

/**
 * Show current interstitial over a given window. This method will show an
 * interstitial and load the next into it.
 *
 * @param window An instance of window to show the interstitial over.
 */
-(void) showOver:(UIWindow *)window;

/**
 * Show current interstitial over a given window and render a specified ad.
 *
 * @param window An instance of window to show the interstitial over.
 * @param ad     The ALAd that you want to render into this interstitial.
 */
-(void) showOver:(UIWindow *)window andRender: (ALAd *) ad;

/**
 * Dismiss current dialog
 */
- (void)dismiss;

/**
 * Init this interstitial ad with a custom AppLovin SDK.
 *
 * To simply display an interstitial, use [ALInterstitialAd showOver:window]
 *
 * @param sdk    Instance of AppLovin SDK to use.
 */
-(id)initInterstitialAdWithSdk: (ALSdk *)anSdk;

/**
 * Init this interstitial ad with a custom AppLovin SDK and custom frame.
 *
 * To simply display an interstitial, use [ALInterstitialAd showOver:window]
 *
 * @param frame  Frame to use with the new interstitial.
 * @param sdk    Instance of AppLovin SDK to use.
 */
- (id)initWithFrame:(CGRect)frame sdk: (ALSdk *) anSdk;

/**
 * Show a new interstitial ad. This method would display a dialog on top of current
 * view with an advertisement in it.
 *
 * @param window  A window to show the interstitial over
 */
+(ALInterstitialAd *) showOver:(UIWindow *)window;

/**
 * Get shared interstitial view
 */
+(ALInterstitialAd *) shared;

@end