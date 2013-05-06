//
//  MPBannerCustomEventDelegate.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MPBannerCustomEvent;

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPBannerCustomEventDelegate <NSObject>

/*
 * This method provides a root view controller that you should use for displaying modal content.
 * It returns the same view controller that you specify when implementing the MPAdViewDelegate
 * protocol.
 */
- (UIViewController *)viewControllerForPresentingModalView;

/*
 * Your custom event subclass must call this method when it successfully loads an ad.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didLoadAd:(UIView *)ad;

/*
 * Your custom event subclass must call this method when it fails to load an ad.
 * Failure to do so will disrupt the mediation waterfall and cause future ad requests to stall.
 */
- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didFailToLoadAdWithError:(NSError *)error;

/*
 * Your custom event subclass should call this method when the user taps on a banner ad.
 * This method is optional; however, if you call it, you must also call either
 * -bannerCustomEventDidFinishAction: or -bannerCustomEventWillLeaveApplication at a later point.
 */
- (void)bannerCustomEventWillBeginAction:(MPBannerCustomEvent *)event;

/*
 * Your custom event subclass should call this method when the user is finished interacting
 * with the banner ad (e.g. dismisses any modal content). This method is optional.
 */
- (void)bannerCustomEventDidFinishAction:(MPBannerCustomEvent *)event;

/*
 * Your custom event subclass should call this method if the ad will cause the user to leave the
 * application (e.g. for the App Store or Safari). This method is optional.
 */
- (void)bannerCustomEventWillLeaveApplication:(MPBannerCustomEvent *)event;

@end
