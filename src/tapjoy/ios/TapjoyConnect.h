// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


/*! \mainpage Tapjoy iOS SDK
 *
 * The Tapjoy iOS SDK.
 */


#import <UIKit/UIkit.h>
#import "TapjoyConnectConstants.h"
#if !defined (TJC_CONNECT_SDK)
#import "TJCAdDelegateProtocol.h"
#import "TJCVideoAdProtocol.h"
#endif


#define TJC_LIBRARY_VERSION_NUMBER			@"9.0.0"				/*!< The SDK version number. */

@class TJCCallsWrapper;
@class TJCAdManager;
@class TJCEventTrackingManager;
@class TJCFullScreenAdManager;
@class TJCOffersManager;
@class TJCDailyRewardAdManager;
@class TJCUserAccountManager;
@class TJCVideoManager;
@class TJCViewCommons;
@class TJCNetReachability;
@class TJCUtil;

/*!	\interface TapjoyConnect
 *	\brief The Tapjoy Connect Main class.
 *
 */
@interface TapjoyConnect :  NSObject

@property (nonatomic, copy) NSString *appID;			/*!< The application ID unique to this app. */
@property (nonatomic, copy) NSString *secretKey;		/*!< The Tapjoy secret key for this applicaiton. */
@property (nonatomic, copy) NSString *userID;			/*!< The user ID, a custom ID set by the developer of an app to keep track of its unique users. */
@property (nonatomic, copy) NSString *plugin;			/*!< The name of the plugin used. If no plugin is used, this value is set to "native" by default. */
@property (nonatomic, assign) float currencyMultiplier;	/*!< The currency multiplier value, used to adjust currency earned. */


@property (nonatomic, retain) TJCCallsWrapper *callsWrapper;
@property (nonatomic, retain) TJCAdManager *displayAdManager;
@property (nonatomic, retain) TJCEventTrackingManager *eventTrackingManager;
@property (nonatomic, retain) TJCFullScreenAdManager *fullScreenAdManager;
@property (nonatomic, retain) TJCOffersManager *offersManager;
@property (nonatomic, retain) TJCDailyRewardAdManager *dailyRewardManager;
@property (nonatomic, retain) TJCUserAccountManager *userAccountManager;
@property (nonatomic, retain) TJCVideoManager *videoManager;
@property (nonatomic, retain) TJCViewCommons *viewCommons;
@property (nonatomic, retain) TJCUtil *util;


/*!	\fn requestTapjoyConnect:secretKey:(NSString *appID, NSString *secretKey)
 *	\brief This method is called to initialize the TapjoyConnect system.
 *
 * This method should be called upon app delegate initialization in the applicationDidFinishLaunching method.
 *	\param appID The application ID. Retrieved from the app dashboard in your Tapjoy account.
 *  \param secretKey The application secret key. Retrieved from the app dashboard in your Tapjoy account.
 *	\return n/a
 */
+ (void)requestTapjoyConnect:(NSString*)appID secretKey:(NSString*)secretKey;

+ (void)requestTapjoyConnect:(NSString*)appID secretKey:(NSString*)secretKey options:(NSDictionary*)optionsDict;

/*!	\fn actionComplete:(NSString*)actionID
 *	\brief This is called when an action is completed.
 *
 * Actions are much like connects, except that this method is only called when a user completes an in-game action.
 *	\param actionID The action ID.
 *	\return n/a
 */
+ (void)actionComplete:(NSString*)actionID;

/*!	\fn sharedTapjoyConnect
 *	\brief Retrieves the globally accessible #TapjoyConnect singleton object.
 *
 *	\param n/a
 *	\return The globally accessible #TapjoyConnect singleton object.
 */
+ (TapjoyConnect*)sharedTapjoyConnect;

/*!	\fn getAppID
 *	\brief Retrieves the Tapjoy app ID.
 *
 *	\param n/a
 *	\return The Tapjoy app ID passed into requestTapjoyConnect.
 */
+ (NSString*)getAppID;

/*!	\fn setUserID:(NSString*)theUserID
 *	\brief Sets the user ID.
 *
 * The user ID defaults to the UDID. This is only changed when NOT using Tapjoy Managed Currency.
 *	\param theUserID The user ID.
 *	\return n/a
 */
+ (void)setUserID:(NSString*)theUserID;

/*!	\fn getUserID
 *	\brief Retrieves the user ID.
 *
 *	\param n/a
 *	\return The Tapjoy user ID. The user ID defaults to the UDID. If UDID is opted out, this returns null.
 */
+ (NSString*)getUserID;

/*!	\fn getSecretKey
 *	\brief Retrieves the secret.
 *
 *	\param n/a
 *	\return The Tapjoy secret key for this application.
 */
+ (NSString*)getSecretKey;

/*!	\fn setPlugin:(NSString*)thePlugin
 *	\brief Sets the plugin.
 *
 * The plugin defaults to "native".
 *	\param thePlugin The name of the plugin.
 *	\return n/a
 */
+ (void)setPlugin:(NSString*)thePlugin;

/*!	\fn setCurrencyMultiplier:(float)mult
 *	\brief Sets the currency multiplier for virtual currency to be earned.
 *
 *	\param mult The currency multiplier.
 *	\return n/a
 */
+ (void)setCurrencyMultiplier:(float)mult;

/*!	\fn getCurrencyMultiplier
 *	\brief Gets the currency multiplier for virtual currency to be earned.
 *
 *	\param n/a
 *	\return The currency multiplier value.
 */
+ (float)getCurrencyMultiplier;

/*!	\fn enableLogging:(BOOL)enable
 *	\brief Toggle logging to the console.
 *
 *	\param enable YES to enable logging, NO otherwise.
 *	\return n/a
 */
+ (void)enableLogging:(BOOL)enable;

@end


#if !defined (TJC_CONNECT_SDK)
@interface TapjoyConnect (TJCAdManager)

/*!	\fn getDisplayAdWithDelegate:(id<TJCAdDelegate>)deleg
 *	\brief Initiates a URL request to get the Tapjoy Ad data.
 *
 *	\param deleg The class instance that implements the TJCAdDelegate protocol.
 *	\return The TJCAdView object.
 */
+ (id) getDisplayAdWithDelegate:(id <TJCAdDelegate>)deleg;

/*!	\fn getDisplayAdWithDelegate:(id<TJCAdDelegate>)deleg currencyID:(NSString*)currencyID
 *	\brief Initiates a URL request to get the Tapjoy Ad data.
 *
 *	\param deleg The class instance that implements the TJCAdDelegate protocol.
 *	\param currencyID The currency ID specifies which currency to advertise in the display ad.
 *	\return The TJCAdView object.
 */
+ (id) getDisplayAdWithDelegate:(id<TJCAdDelegate>)deleg currencyID:(NSString*)currencyID;

/*!	\fn refreshDisplayAd
 *	\brief Attempts to load a new Ad.
 *
 *	\param n/a
 *	\return n/a
 */
+ (void) refreshDisplayAd TJC_DEPRECATION_WARNING;

/*!	\fn refreshDisplayAdWithCurrencyID:(NSString*)currencyID
 *	\brief Attempts to load a new Ad.
 *
 *	\param currencyID The currency ID specifies which currency to advertise in the display ad.
 *	\return n/a
 */
+ (void) refreshDisplayAdWithCurrencyID:(NSString*)currencyID TJC_DEPRECATION_WARNING;

/*!	\fn isDisplayAdLoaded
 *	\brief Indicates whether ad data has been successfully loaded.
 *
 *	\param n/a
 *	\return YES to indicate that the ad data has been successfully loaded, NO otherwise.
 */
+ (BOOL) isDisplayAdLoaded;

/*!	\fn getDisplayAdView
 *	\brief The Tapjoy Display Ad UIView returned by this method should be added to the current superview after an Ad has been successfully loaded.
 *
 *	\param n/a
 *	\return The Tapjoy Display Ad UIView.
 */
+ (TJCAdView*) getDisplayAdView;

@end


@interface TapjoyConnect (TJCEventTrackingManager)

/*!	\fn sendIAPEvent
 *	\brief Initiates the request to POST the IAP data.
 *
 *	\param name The name of the In-App-Purchase (IAP) item that this event should track.
 *	\param price The amount that the item was sold for.
 *	\param quantity The number of items for this purchase.
 *	\param currencyCode The currency code, such as USD.
 *  \return n/a
 */
+ (void)sendIAPEvent:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode;

+ (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode TJC_DEPRECATION_WARNING;

@end


@interface TapjoyConnect (TJCFullScreenAdManager)

/*!	\fn getFullScreenAd
 *	\brief Requests for Featured App are notified via the TJC_FULL_SCREEN_AD_RESPONSE_NOTIFICATION notification.
 *
 *	\param n/a
 *	\return n/a
 */
+ (void)getFullScreenAd;

/*!	\fn getFullScreenAdWithCurrencyID:(NSString*)currencyID
 *	\brief Requests for Featured App are notified via the TJC_FULL_SCREEN_AD_RESPONSE_NOTIFICATION notification.
 *
 *	\param currencyID The GUID for the currency earned when completing this full screen ad.
 *	\return n/a
 */
+ (void)getFullScreenAdWithCurrencyID:(NSString*)currencyID;

/*!	\fn showFullScreenAd
 *	\brief Wrapper method for displaying the Full Screen Featured App Ad.
 *
 * Places the Full Screen Ad UIView on the top of the view stack and animates it into view if an animation transition effect is set.
 *	\param n/a
 *	\return The #TJCUIWebPageAdView object.
 */
+ (UIView*)showFullScreenAd;

/*!	\fn showFullScreenAdWithViewController:(UIViewController*)vController
 *	\brief Wrapper method for displaying the Full Screen Featured App Ad.
 *
 * Places the Full Screen Ad UIView on the top of the view stack and animates it into view if an animation transition effect is set.
 *	\param vController Reference to the application's view Controller. (Note: It must not be nil or an invalid object).
 *	\return n/a
 */
+ (void)showFullScreenAdWithViewController:(UIViewController*)vController;

/*!	\fn setFullScreenAdDelayCount:(int)delayCount
 *	\brief Sets the delay count for full screen ad.
 *
 *	\param delayCount The number of times that the app must run (since initial app install) before a full screen ad can be displayed.
 *	\return n/a
 */
+ (void)setFullScreenAdDelayCount:(int)delayCount;

+ (void)getFeaturedApp TJC_DEPRECATION_WARNING;
+ (void)getFeaturedAppWithCurrencyID:(NSString*)currencyID TJC_DEPRECATION_WARNING;
+ (UIView*)showFeaturedAppFullScreenAd TJC_DEPRECATION_WARNING;
+ (void)showFeaturedAppFullScreenAdWithViewController:(UIViewController*)vController TJC_DEPRECATION_WARNING;
+ (void)setFeaturedAppDisplayCount:(int) displayCount TJC_DEPRECATION_WARNING;
+ (void)setFeaturedAppDelayCount:(int)delayCount TJC_DEPRECATION_WARNING;

@end


@interface TapjoyConnect (TJCOffersManager)

/*!	\fn showOffers
 *	\brief Allocates and initializes a #TJCOffersWebView.
 *
 *	\return The #TJCOffersWebView UIView object.
 */
+ (UIView*)showOffers;

/*!	\fn showOffersWithViewController:(UIViewController*)vController
 *	\brief Allocates and initializes a #TJCOffersWebView.
 *
 *	\param vController The UIViewController to set as #TJCOffersWebView's #parentVController_.
 *	\return n/a
 */
+ (void)showOffersWithViewController:(UIViewController*)vController;

/*!	\fn showOffersWithCurrencyID:withCurrencySelector:(NSString *currencyID, BOOL isSelectorVisible)
 *	\brief Allocates and initializes a #TJCOffersWebView. This is only used when multiple currencies are enabled.
 *
 *	\param currencyID The id of the currency to show in the offer wall.
 *	\param isSelectorVisible Specifies whether to display the currency selector in the offer wall.
 *	\return The #TJCOffersWebView UIView object.
 */
+ (UIView*)showOffersWithCurrencyID:(NSString*)currencyID withCurrencySelector:(BOOL)isSelectorVisible;

/*!	\fn showOffersWithCurrencyID:withViewController:withCurrencySelector:(NSString *currencyID, UIViewController *vController, BOOL isSelectorVisible)
 *	\brief Allocates and initializes a #TJCOffersWebView. This is only used when multiple currencies are enabled.
 *
 *	\param vController The UIViewController to set as #TJCOffersWebView's #parentVController_.
 *	\param currencyID The id of the currency to show in the offer wall.
 *	\param isSelectorVisible Specifies whether to display the currency selector in the offer wall.
 *	\return n/a
 */
+ (void)showOffersWithCurrencyID:(NSString*)currencyID withViewController:(UIViewController*)vController withCurrencySelector:(BOOL)isSelectorVisible;

/*!	\fn showOffersWithViewController:withInternalNavBar:(UIViewController* vController, BOOL visible)
 *	\brief Allocates and initializes a #TJCOffersWebView.
 *
 *	\param vController The UIViewController to set as #TJCOffersWebView's #parentVController_.
 *	\param visible TRUE makes the navigation bar visible, FALSE makes it not visible.
 *	\return n/a
 */
+ (void)showOffersWithViewController:(UIViewController*)vController withInternalNavBar:(BOOL)visible TJC_DEPRECATION_WARNING;

/*!	\fn showOffersWithCurrencyID:withViewController:withInternalNavBar:withCurrencySelector:(NSString *currencyID, UIViewController *vController, BOOL visible, BOOL isSelectorVisible)
 *	\brief Allocates and initializes a #TJCOffersWebView. This is only used when multiple currencies are enabled.
 *
 *	\param vController The UIViewController to set as #TJCOffersWebView's #parentVController_.
 *	\param visible TRUE makes the navigation bar visible, FALSE makes it not visible.
 *	\param currencyID The id of the currency to show in the offer wall.
 *	\param isSelectorVisible Specifies whether to display the currency selector in the offer wall.
 *	\return n/a
 */
+ (void)showOffersWithCurrencyID:(NSString*)currencyID
withViewController:(UIViewController*)vController
withInternalNavBar:(BOOL)visible
withCurrencySelector:(BOOL)isSelectorVisible TJC_DEPRECATION_WARNING;

/*!	\fn setOffersNavBarImage:(UIImage*)image
 *	\brief Sets the navigation bar background image.
 *
 *	\param image The UIImage to set the offer wall's navigation bar's background image to.
 *  \return n/a
 */
+ (void)setOffersNavBarImage:(UIImage*)image TJC_DEPRECATION_WARNING;

@end


@interface TapjoyConnect (TJCDailyRewardManager)

/*!	\fn getDailyRewardAd
 *	\brief Requests for daily reward are notified via the TJC_DAILY_REWARD_RESPONSE_NOTIFICATION notification.
 *
 *	\param n/a
 *	\return n/a
 */
+ (void)getDailyRewardAd;

/*!	\fn getDailyRewardAdWithCurrencyID:(NSString*)currencyID
 *	\brief Requests for Daily reward are notified via the TJC_DAILY_REWARD_RESPONSE_NOTIFICATION notification.
 *
 *	\param currencyID The GUID for the currency earned when completing this full screen ad.
 *	\return n/a
 */
+ (void)getDailyRewardAdWithCurrencyID:(NSString*)currencyID;

/*!	\fn showDailyRewardAd
 *	\brief Wrapper method for displaying the Daily reward.
 *
 * Places the Daily reward UIView on the top of the view stack and animates it into view if an animation transition effect is set.
 *	\param n/a
 *	\return The #TJCUIWebPageAdView object.
 */
+ (UIView*)showDailyRewardAd;

/*!	\fn showDailyRewardAdWithViewController:(UIViewController*)vController
 *	\brief Wrapper method for displaying the daily reward Ad.
 *
 * Places the daily reward Ad UIView on the top of the view stack and animates it into view if an animation transition effect is set.
 *	\param vController Reference to the application's view Controller. (Note: It must not be nil or an invalid object).
 *	\return n/a
 */
+ (void)showDailyRewardAdWithViewController:(UIViewController*)vController;

@end


@interface TapjoyConnect (TJCUserAccountManager)

/*!	\fn getTapPoints
 *	\brief Requests for Tap Points (Virtual Currency) notify via TJC_TAP_POINTS_RESPONSE_NOTIFICATION notification.
 *
 *	\param n/a
 *	\return n/a
 */
+ (void)getTapPoints;

/*!	\fn spendTapPoints:(int)points
 *	\brief Updates the virtual currency for the user with the given spent amount of currency.
 *
 * If the spent amount exceeds the current amount of currency the user has, nothing will happen.
 *	\param points The amount of currency to subtract from the current total amount of currency the user has.
 *	\return n/a
 */
+ (void)spendTapPoints:(int)points;

/*!	\fn awardTapPoints:(int)points
 *	\brief Updates the virtual currency for the user with the given awarded amount of currency.
 *
 *	\param points The amount of currency to add to the current total amount of currency the user has.
 *	\return n/a
 */
+ (void)awardTapPoints:(int)points;

/*!	\fn showDefaultEarnedCurrencyAlert
 *	\brief Shows a UIAlert that tells the user how much currency they just earned.
 *
 *	\param n/a
 *	\return n/a
 */
+ (void)showDefaultEarnedCurrencyAlert;

@end


@interface TapjoyConnect (TJCVideoViewHandler)

/*!	\fn initVideoAdWithDelegate:(id<TJCVideoAdDelegate>)delegate
 *	\brief Initializes video ads.
 *
 *	\param delegate The class that implements the TJCVideoAdDelegate protocol.
 *	\return n/a
 */
+ (void)initVideoAdWithDelegate:(id<TJCVideoAdDelegate>)delegate TJC_DEPRECATION_WARNING;

/*!	\fn cacheVideosWithDelegate:(id<TJCVideoAdDelegate>)delegate
 *	\brief Begins the caching process if auto caching is disabled.
 *
 *	\param delegate The class that implements the TJCVideoAdDelegate protocol.
 *	\return n/a
 */
+ (void)cacheVideosWithDelegate:(id<TJCVideoAdDelegate>)delegate;

/*!	\fn setVideoCacheCount:(int)count
 *	\brief Sets the cache count for video ads.
 *
 *	\param count The number of videos to cache to device locally.
 *	\return n/a
 */
+ (void)setVideoCacheCount:(int)count;

/*!	\fn shouldDisplayVideoLogo:(BOOL)display
 *	\brief Set the visibility of the Tapjoy logo during video playback.
 *
 *	\param display Boolean that indicates whether the Tapjoy logo should be displayed or not during video playback.
 *	\return n/a
 */
+ (void)shouldDisplayVideoLogo:(BOOL)display;

/*!	\fn disableVideo:(BOOL)shouldDisable
 *	\brief Whether the videos should be disabled on this device during runtime. If set to true, no videos will be
 *  cached nor displayed on the offerwall for streaming (wi-fi only)
 *
 *	\param shouldDisableVideo Boolean that indicates whether the Tapjoy videos should be disabled on this device.
 *	\return n/a
 */
+ (void)disableVideo:(BOOL)shouldDisable;

@end


@interface TapjoyConnect (TJCViewCommons)

/*!	\fn setTransitionEffect:(TJCTransitionEnum) transitionEffect
 *	\brief Sets a transition effect for the Tapjoy UIViews.
 *
 *	\param transitionEffect The transition effect to set, enumerated by #TJCTransitionEnum.
 *	\return n/a
 */
+ (void)setTransitionEffect:(TJCTransitionEnum)transitionEffect;

/*!	\fn getTransitionDelay
 *	\brief Gets the transition delay.
 *
 *	\param n/a
 *  \return The transition delay.
 */
+ (float)getTransitionDelay;

/*!	\fn getCurrentTransitionEffect
 *	\brief Gets the currently set transition effect enumerated value #TJCTransitionEnum.
 *
 *	\param n/a
 *  \return The currently set transition effect.
 */
+ (TJCTransitionEnum)getCurrentTransitionEffect;

/*!	\fn getReverseTransitionEffect
 *	\brief Gets the currently set reverse transition effect enumerated value #TJCTransitionEnum.
 *
 *	\param n/a
 *  \return The currently set reverse transition effect.
 */
+ (TJCTransitionEnum)getReverseTransitionEffect;

/*!	\fn setUserdefinedColorWithIntValue:(int) colorValue
 *	\brief Sets the navigation bar color with the given color value.
 *
 *	\param colorValue The color to set the navigation bar to.
 *	\return n/a
 */
+ (void)setUserdefinedColorWithIntValue:(int) colorValue TJC_DEPRECATION_WARNING;

/*!	\fn setUserDefinedColorWithRed:WithGreen:WithBlue:(int red, int green, int blue)
 *	\brief Sets the navigation bar color with the given color values.
 *
 *	\param red The red color component.
 *	\param green The green color component.
 *	\param blue The blue color component.
 *	\return n/a
 */
+ (void)setUserDefinedColorWithRed:(int)red WithGreen:(int)green WithBlue:(int)blue TJC_DEPRECATION_WARNING;

@end

#endif
