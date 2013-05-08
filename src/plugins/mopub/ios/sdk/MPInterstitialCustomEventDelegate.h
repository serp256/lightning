//
//  MPInterstitialCustomEventDelegate.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPInterstitialCustomEvent;

@protocol MPInterstitialCustomEventDelegate <NSObject>

/*
 * Your custom event subclass must call this method when it successfully loads an ad.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
                      didLoadAd:(id)ad;

/*
 * Your custom event subclass must call this method when it fails to load an ad.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
       didFailToLoadAdWithError:(NSError *)error;

/*
 * Your custom event subclass must call this method when it is about to present the interstitial
 * ad. Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)interstitialCustomEventWillAppear:(MPInterstitialCustomEvent *)customEvent;

/*
 * Your custom event subclass must call this method when the interstitial is presented.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 * Note: if it is not possible to know when the interstitial *finished* appearing, you should call
 * this immediately after calling interstitialCustomEventWillAppear:.
 */
- (void)interstitialCustomEventDidAppear:(MPInterstitialCustomEvent *)customEvent;

/*
 * Your custom event subclass must call this method when it is about to dismiss the interstitial
 * ad. Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)interstitialCustomEventWillDisappear:(MPInterstitialCustomEvent *)customEvent;

/*
 * Your custom event subclass must call this method when the interstitial is dismissed.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 * Note: if it is not possible to know when the interstitial *finished* dismissing, you should call
 * this immediately after calling interstitialCustomEventDidDisappear:.
 */
- (void)interstitialCustomEventDidDisappear:(MPInterstitialCustomEvent *)customEvent;

/*
 * Your custom event subclass may call this method when the interstitial is tapped.
 * This method is optional and only serves to allow MoPub to track clicks.
 * You do not need to guard against calling this multiple times.  Only one click is tracked
 * per ad.
 *
 * Note: some third-party networks provide a "will leave application" callback instead of/in
 * addition to a "user did click" callback. You should call this method in response to either of
 * those callbacks (since leaving the application is generally an indicator of a user tap).
 */
- (void)interstitialCustomEventDidReceiveTapEvent:(MPInterstitialCustomEvent *)customEvent;

@end
