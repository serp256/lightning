//
//  SPBrandEngageClient.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SPBrandEngageClientDelegate.h"


@class SPBrandEngageClient;

/** Provides methods to request and show BrandEngage offers, notifies its delegate of the availability of offers and of changes in the status of the engagement.
 
 Before requesting offers, make sure of having set your app ID, current user ID and currency name, as well as one of your objects as the delegate. At this point you can determine if offers are available with requestOffers. If your delegate is notified that offers are available, run them by invoking startWithParentViewController:, and your delegate will be notified when the engagement has closed. When the engagement is over you must restart the process, querying if offers are available, before you run any engagement again.
 
 To check for new virtual coins earned by the user, given you've set your VCS key, use SPVirtualCurrencyServerConnector.
 
 @warning Offer availability (requestOffers) cannot be requested while an engagement is running. Call canRequestOffers if you're not sure that this instance is in a state in which a request for offers is possible.
 
 */

@interface SPBrandEngageClient : NSObject

/** Name of your virtual currency.
 This is a human readable, descriptive name of your virtual currency.
 @see SponsorPaySDK
 */
@property (nonatomic, copy, readonly) NSString *currencyName;

/**
 *  The ID of the placement
 */
@property (nonatomic, copy) NSString *placementId;

/** @name Receiving asynchronous callbacks */

/** Instance of one of your classes implementing the SPBrandEngageClientDelegate protocol, which will be notified of offers availability and engagement status.
 @see SPBrandEngageClientDelegate.
 */
@property (weak) id<SPBrandEngageClientDelegate> delegate;

/** @name Controlling notifications to the user */

/** Whether the SDK should show a toast-like notification to the user when they come back to your application after completing an engagement.
 
 An example notification would be "Thanks! Your reward will be paid out shortly".
 
 Default value is YES.
  */
@property (assign) BOOL shouldShowRewardNotificationOnEngagementCompleted;

/** @name Requesting offers */

/** Returns whether this instance is in a state in which it's possible to query the server for offers availability.
 
 Offer availability cannot be requested while an engagement is running or the server is currently being queried. Call this method if you're not sure that if this instance is in a state in which a request for offers is possible.
 
 @return YES if a request for offers can be currently initiated, NO otherwise. If NO is returned, a call to requestOffers will notify your delegate of an error.
 */
- (BOOL)canRequestOffers;

/** Queries the server for BrandEngage offers availability.
 
 Before you start running an engagement, you must call requestOffers and wait until your code is notified that offers are indeed available.
 
 The answer to the request will be delivered asynchronously to your code via the registered SPBrandEngageClientDelegate.
 
 Offer availability cannot be requested while an engagement is running or the server is currently being queried. Call canRequestOffers if you're not sure that this instance is in a state in which a request for offers is possible.
 
 @return YES if a request for offers was initiated, NO if the request cannot be initiated. If NO is returned, this call had no effect and you need to invoke this method again when a request for offers is possible.
 
 @see canRequestOffers
 */
- (BOOL)requestOffers;

/**
 *  Same as requestOffers with the the provided placementId to the server
 *
 *  @param placementId The ID of the placement
 *
 */
- (BOOL)requestOffersForPlacementId:(NSString *)placementId;

/**
 *  Same as requestOffers with the provided placementId to the server. Additionally, the SPBrandEngageClient will automatically send a request for the currency upon engagement completion and notify the supplied vcsDelegate.
 *
 *  @param placementId The ID of the placement
 *  @param currencyId  The currency id to query the currency delta or nil to query the default currency
 *  @param vcsDelegate The delegate to notify when the currency delta request finishes. If nil is supplied, no currency delta will be queried. The receiver maintains a weak reference to vcsDelegate.
 *
 *  @return YES if a request was sent
 */
- (BOOL)requestOffersForPlacementId:(NSString *)placementId queryVCSWithCurrencyId:(NSString *)currencyId vcsDelegate:(id<SPVirtualCurrencyConnectionDelegate>)vcsDelegate;

/** @name Running offers */

/** Returns whether this instance is in a state in which it's possible to start running an engagement.
 
 Most of the time you won't have to call this method, but if you've lost track of whether this instance can start showing an engagement, this will let you know.
 
 An engagement or offer cannot be started while another one is active, while the server is being queried, or after another engagement has closed if new offers have not been requested with requestOffers.
 
 @return YES if an engagement can be initiated, NO otherwise.
 
 @see startWithParentViewController:
 */
- (BOOL)canStartOffers;

/** Starts running an available engagement.
 
 The engagement player will take over the screen while the engagement is running. Its view controller will be shown as a modal child of your own view controller.
 
 If the offer cannot be run (because requestOffers wasn't previously called or it didn't report available offers) this call will return NO.
 
 @param parentViewController Your own view controller which will act as presenting or parent view controller for the engagement player.
 
 @return YES if the engagement will start, NO otherwise.
 */
- (BOOL)startWithParentViewController:(UIViewController *)parentViewController;

/** @name Determining if it is safe to modify parameters */

/** Determines whether it is possible to add or modify, at the point of invocation, this instance's custom parameters specified with setCustomParamWithKey:value:
 
 These publisher parameters cannot be added or modified while the server is being queried or an engagement is running. In these cases a call to setCustomParamWithKey:value: will have no effect.
 
 @return YES if the properties can be modified at this point, NO otherwise.
 */
- (BOOL)canChangePublisherParameters;

/** @name Setting arbitrary custom parameters */

/** Sets a custom key and value to be sent to the server on the next request for offers availability.
 
 @param key Arbitrary key name for the custom param to set.
 @param value Arbitrary value string for the custom param to set.
 @returns YES if the parameter was set, NO otherwise.
 
 @see canChangePublisherParameters.
  */
- (BOOL)setCustomParamWithKey:(NSString *)key value:(NSString *)value;

@end
