//
//  MPInterstitialCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPInterstitialCustomEventDelegate.h"

/*
 * MPInterstitialCustomEvent is a base class for custom events that support full-screen interstitial
 * ads. By implementing subclasses of MPInterstitialCustomEvent, you can enable the MoPub SDK to
 * natively support a wider variety of third-party ad networks, or execute any of your application
 * code on demand.
 *
 * At runtime, the MoPub SDK will find and instantiate a MPInterstitialCustomEvent subclass as
 * needed and invoke its -requestInterstitialWithCustomEventInfo: method.
 */
@interface MPInterstitialCustomEvent : NSObject

/*
 * When the MoPub SDK receives a response indicating it should load a custom event, it will send
 * this message to your custom event class. Your implementation of this method can either load a
 * interstitial ad from a third-party ad network, or execute any application code. It must also
 * notify the MPInterstitialCustomEventDelegate of certain lifecycle events.
 *
 * The `info` parameter is a dictionary containing additional custom data that you want to
 * associate with a given custom event request. This data is configurable on the MoPub website,
 * and may be used to pass dynamic information, such as publisher IDs.
 */
- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info;

/*
 * This message is sent sometime after an interstitial has been successfully loaded, as a result
 * of your code calling -[MPInterstitialAdController showFromViewController:]. Your implementation
 * of this method should present the interstitial ad from the specified view controller.
 */
- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController;

/*
 * The `delegate` object defines several methods that you should call in order to inform both MoPub
 * and your MPInterstitialAdController's delegate of the progress of your custom event. At a
 * minimum, you are required to call the -interstitialCustomEvent:didLoadAd: and 
 * -interstitialCustomEvent:didFailToLoadAdWithError: methods in order for MoPub's
 * mediation behavior to work properly.
 */
@property (nonatomic, assign) id<MPInterstitialCustomEventDelegate> delegate;

@end
