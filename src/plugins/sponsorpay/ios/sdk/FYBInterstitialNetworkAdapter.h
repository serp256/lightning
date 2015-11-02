//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FYBInterstitialControllerDismissReason.h"
#import "FYBInterstitialNetworkAdapterDelegate.h"

@class FYBBaseNetwork;

/**
 * Defines the interface required by an interstitial network SDK wrapper
 */
@protocol FYBInterstitialNetworkAdapter<NSObject>

/**
 * Arbitrary offer data that can be written and read by the Fyber SDK to keep track of context
 * This property needs to be synthesized in the adapter implementation
 */
@property (nonatomic, strong) NSDictionary *offerData;

/**
 * Returns the name of the interstitial-providing network wrapped by this adapter
 */
- (NSString *)networkName;

/**
 * Sets the delegate to be notified of interstitial availability and lifecycle
 */
- (void)setDelegate:(id<FYBInterstitialNetworkAdapterDelegate>)delegate;

/**
 * Starts the interstitial adapter with its corresponding credentials and starts the
 * interstitial caching process if available
 */
- (BOOL)startAdapterWithDict:(NSDictionary *)dict;

/**
 * Checks whether the provider has any interstitial ads available
 */
- (BOOL)canShowInterstitial;

/**
 * Instructs the interstitial provider to show the interstitial. An interstitial
 * ad must be available for this call to succeed
 *
 * @param viewController If the provider supports showing the interstitial as a child
 * of an existing view controller, the passed viewController will be used as the parent
 * view controller. Otherwise the passed view controller will be ignored
 */
- (void)presentInterstitialFromViewController:(UIViewController *)viewController;

- (void)setNetwork:(FYBBaseNetwork *)network;

@end
