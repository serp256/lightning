//
//  SPInterstitialNetworkAdapter.h
//  SponsorPayTestApp
//
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SPInterstitialNetworkAdapterDelegate;
@class SPBaseNetwork;

/**
 * Defines the interface required by a video network SDK wrapper.
 */
@protocol SPInterstitialNetworkAdapter <NSObject>

/**
 * Returns the name of the interstitial-providing network wrapped by this adapter.
 */
- (NSString *)networkName;

/**
 * Sets the delegate to be notified of interstitial availability and lifecycle.
 */
- (void)setDelegate:(id<SPInterstitialNetworkAdapterDelegate>)delegate;

/**
 * Starts the interstitial adapter with its corresponding credentials and starts the
 * interstitial caching process if available.
 */
- (BOOL)startAdapterWithDict:(NSDictionary *)dict;

/**
 * Checks whether the provider has any interstitial ads available.
 */
- (BOOL)canShowInterstitial;

/**
 * Instructs the interstitial provider to show the interstitial. An interstitial
 * ad must be available for this call to succeed.
 *
 * @param viewController If the provider supports showing the interstitial as a child
 * of an existing view controller, the passed viewController will be used as the parent
 * view controller. Otherwise the passed view controller will be ignored.
 */
- (void)showInterstitialFromViewController:(UIViewController *)viewController;

- (void)setNetwork:(SPBaseNetwork *)network;
@end

/** Defines the reasons by which an interstitial ad can be dismissed. */
typedef enum {
    /** The interstitial was dismissed for an unknown reason. */
    SPInterstitialDismissReasonUnknown = 0,
    /** The interstitial was closed because the user clicked on the ad. */
    SPInterstitialDismissReasonUserClickedOnAd = 1,
    /** The interstitial was explicitly closed by the user. */
    SPInterstitialDismissReasonUserClosedAd = 2,
} SPInterstitialDismissReason;

/**
 * Protocol that delegates wishing to be notified of interstitial availability
 * and lifecycle must conform to.
 */
@protocol SPInterstitialNetworkAdapterDelegate

/**
 * Informs the delegate that an interstitial ad is being displayed.
 *
 * @param adapter The interstitial adapter that is sending this message.
 */
- (void)adapterDidShowInterstitial:(id<SPInterstitialNetworkAdapter>)adapter;

/**
 * Informs the delegate that the third party adapter closed the interstitial.
 *
 * @param adapter The interstitial adapter that is sending this message.
 * @param SPInterstitialDismissReason The reason by which the interstitial was dismissed. @see SPInterstitialDismissReason
 */
- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason;

/**
 * Informs the delegate that the third party adapter failed with an error.
 *
 * @param adapter The interstitial adapter that is sending this message.
 * @param error An object enclosing the cause of the error.
 */
- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter
    didFailWithError:(NSError *)error;

@end