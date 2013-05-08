//
//  MPInterstitialAdController.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MPAdView.h"
#import "MPGlobal.h"
#import "MPInterstitialAdManager.h"

@protocol MPInterstitialAdControllerDelegate;

@interface MPInterstitialAdController : UIViewController <MPInterstitialAdManagerDelegate>

@property (nonatomic, assign) id<MPInterstitialAdControllerDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL ready;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSString *keywords;
@property (nonatomic, copy) CLLocation *location;
@property (nonatomic, assign) BOOL locationEnabled;
@property (nonatomic, assign) NSUInteger locationPrecision;
@property (nonatomic, assign, getter=isTesting) BOOL testing;

/*
 * Returns the shared pool of interstitial objects for your application.
 */
+ (NSMutableArray *)sharedInterstitialAdControllers;

/*
 * Removes the given interstitial object from the shared pool.
 */
+ (void)removeSharedInterstitialAdController:(MPInterstitialAdController *)controller;

/*
 * Returns an interstitial object matching the given ad unit ID. If no interstitial exists for the
 * ad unit ID, a new object will be created and returned.
 */
+ (MPInterstitialAdController *)interstitialAdControllerForAdUnitId:(NSString *)adUnitId;

/*
 * Begins loading ad content for this interstitial. You should implement the -interstitialDidLoadAd
 * and -interstitialDidFailToLoadAd methods on your delegate object if you would like to be notified
 * as the loading succeeds or fails.
 */
- (void)loadAd;

/*
 * Displays this interstitial modally from the specified view controller.
 */
- (void)showFromViewController:(UIViewController *)controller;

#pragma mark - Deprecated

/*
 * Notifies MoPub that a custom event has successfully loaded an interstitial.
 *
 * DEPRECATED:
 */
- (void)customEventDidLoadAd MOPUB_DEPRECATED;

/*
 * Notifies MoPub that a custom event has failed to load an interstitial.
 *
 * DEPRECATED:
 */
- (void)customEventDidFailToLoadAd MOPUB_DEPRECATED;

/*
 * Notifies MoPub that a user has tapped on a custom event interstitial.
 *
 * DEPRECATED:
 */
- (void)customEventActionWillBegin MOPUB_DEPRECATED;

@end

#pragma mark -

@protocol MPInterstitialAdControllerDelegate <NSObject>

@optional

/*
 * These callbacks notify you when the interstitial (un)successfully loads its ad content. You may
 * implement these if you want to prefetch interstitial ads.
 */
- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial;
- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial;

/*
 * This callback notifies you that the interstitial is about to appear. This is a good time to
 * handle potential app interruptions (e.g. pause a game).
 */
- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial;
- (void)interstitialDidAppear:(MPInterstitialAdController *)interstitial;
- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial;
- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial;

/*
 * Interstitial ads from certain networks (e.g. iAd) may expire their content at any time,
 * regardless of whether the content is currently on-screen. This callback notifies you when the
 * currently-loaded interstitial has expired and is no longer eligible for display. If the ad
 * was on-screen when it expired, you can expect that the ad will already have been dismissed
 * by the time this callback was fired. Your implementation may include a call to -loadAd to fetch a
 * new ad, if desired.
 */
- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial;

/*
 * DEPRECATED: This callback notifies you to dismiss the interstitial, and allows you to implement
 * any pre-dismissal behavior (e.g. unpausing a game). This method is being deprecated as it is no
 * longer necessary to dismiss an interstitial manually (i.e. via calling
 * -dismissModalViewControllerAnimated:).
 *
 * Any pre-dismissal behavior should be implemented using -interstitialWillDisappear: or
 * -interstitialDidDisappear: instead.
 */
- (void)dismissInterstitial:(MPInterstitialAdController *)interstitial MOPUB_DEPRECATED;

@end
