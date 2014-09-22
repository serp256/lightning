//
//  SponsorPaySDK.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPAdvertisementViewController.h"
#import "SPOfferWallViewController.h"
#import "SPVirtualCurrencyServerConnector.h"
#import "SPBrandEngageClient.h"
#import "SPInterstitialClient_SDKPrivate.h"
#import "SPLogger.h"

/**
 Provides convenience class methods to access the functionality of the SponsorPay SDK
 */

@interface SponsorPaySDK : NSObject

/** @name Starting the SDK */

/**
 Starts the SDK, registering your credentials for all subsequent usages of the SDK functionality.

 @param appId Your SponsorPay application ID.
 @param userId ID of the current user of your application.
 @param securityToken Security token assigned to your app ID to authenticate requests to some resources and validate their responses.
 @return A string token that, if you keep several sets of appId - userId combinations, can be used to refer to each one.

 @warning It's necessary to call this method or startWithAutogeneratedUserForAppId:securityToken: at least once every time your app runs in order to be able to use any other functionality of the SDK.
 */
+ (NSString *)startForAppId:(NSString *)appId
                     userId:(NSString *)userId
              securityToken:(NSString *)securityToken;

+ (NSString *)startForAppId:(NSString *)appId
                     userId:(NSString *)userId
              securityToken:(NSString *)securityToken
              withNetworks:(NSArray*)networks;


/**
 Starts the SDK with an autogenerated user, registering your credentials for all subsequent usages of the SDK functionality.

 @param appId Your SponsorPay application ID.
 @param securityToken Security token assigned to your app ID to authenticate requests to some resources and validate their responses.
 @return A string token that, if you keep several sets of appId - userId combinations, can be used to refer to each one.

 @warning It's necessary to call this method or startForAppId:userId:securityToken: at least once every time your app runs in order to be able to use any other functionality of the SDK.
 */
+ (NSString *)startWithAutogeneratedUserForAppId:(NSString *)appId
                                   securityToken:(NSString *)securityToken;

/** @name Using the Mobile OfferWall */

/**
 Returns an SPOfferWallViewController instance configured with the appId and userId passed in a previous invocation of the SDK start method

 @return An instance of SPOfferWallViewController configured with the appId and userId provided previously to the SDK start method.

 @see showOfferWallWithParentViewController:

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use the OfferWall with more than one appId - userId combination, refer to  offerWallViewControllerForCredentials: instead.
 */
+ (SPOfferWallViewController *)offerWallViewController;


/**
 Returns an SPOfferWallViewController instance configured with the appId and userId passed in a previous invocation of the SDK start method

 @param credentialsToken The credentials string token returned by a previous invocation of the SDK start method whose appId and userId will be configured in the returned SPOfferWallViewController instance. If you pass an invalid credentials token, this method will throw an exception.

 @return An instance of SPOfferWallViewController configured with the appId and userId corresponding to the provided credentials token.
*/
+ (SPOfferWallViewController *)offerWallViewControllerForCredentials:(NSString *)credentialsToken;


/**
 Presents the SponsorPay Mobile OfferWall as a child view controller of your own view controller.

 @param parent An instance of your own UIViewController subclass that will be used as the parent view controller of the presented OfferWall. It must conform to the SPOfferWallViewControllerDelegate protocol, and will be notified whenever the OfferWall is closed.

 @return The instance of SPOfferWallViewController which is being presented.

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use the OfferWall with more than one appId - userId combination, refer to  offerWallViewControllerForCredentials: instead.
 */
+ (SPOfferWallViewController *)showOfferWallWithParentViewController:(UIViewController<SPOfferWallViewControllerDelegate> *)parent;

/** @name Requesting and showing Mobile Brand Engage offers */

/**
 Returns an SPBrandEngageClient instance configured with the appId and userId passed in a previous invocation of the SDK start method

 @return An instance of SPBrandEngageClient configured with the appId and userId provided previously to the SDK start method.

 @see requestBrandEngageOffersNotifyingDelegate:

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use Mobile BrandEngage with more than one appId - userId combination, refer to  brandEngageClientForCredentials: instead.
 */
+ (SPBrandEngageClient *)brandEngageClient;

/**
 Returns an SPBrandEngageClient instance configured with the appId and userId passed in a previous invocation of the SDK start method

 @param credentialsToken The credentials string token returned by a previous invocation of the SDK start method whose appId and userId will be configured in the returned SPBrandEngageClient instance. If you pass an invalid credentials token, this method will throw an exception.

 @return An instance of SPBrandEngageClient configured with the appId and userId corresponding to the provided credentials token.
 */
+ (SPBrandEngageClient *)brandEngageClientForCredentials:(NSString *)credentialsToken;

/**
 Returns an SPBrandEngageClient instance configured with the appId and userId passed in a previous invocation of the SDK start method and your own delegate, and starts requesting an available BrandEngage offer immediately.

 @return An instance of SPBrandEngageClient configured with your delegate object and the appId and userId provided previously to the SDK start method.

 @see SPBrandEngageClientDelegate
 @see [SPBrandEngageClient requestOffers]

 @param delegate Instance of one of your classes implementing the SPBrandEngageClientDelegate protocol, which will be notified of offers availability and engagement status.

 @see SPBrandEngageClientDelegate.

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use Mobile BrandEngage with more than one appId - userId combination, refer to  brandEngageClientForCredentials: instead.
 */
+ (SPBrandEngageClient *)requestBrandEngageOffersNotifyingDelegate:(id<SPBrandEngageClientDelegate>)delegate;

/** @name Accessing the Interstitial client */

/**
 Returns an SPInterstitialClient instance configured with the appId (and potentially userId) passed in a previous invocation of any of the SDK start methods (startForAppId:userId:securityToken: or startWithAutogeneratedUserForAppId:securityToken:). There is a unique instance of SPInterstitialClient per app. If you have started the SDK more than once with different combinations of appId and userId, the combination used to configure the SPInterstitialClient will be the one specified when calling the method setCredentialsForInterstitial: (provided that this method was called before accessing the interstitialClient instance for the first time). If this method had been not called prior to accessing the interstitialClient, the appId - userId combination selected will be the one used to start the SDK for the first time.

 @see startForAppId:userId:securityToken:
 @see startWithAutogeneratedUserForAppId:securityToken:
 @see setCredentialsForInterstitial:
 */
+ (SPInterstitialClient *)interstitialClient;

/**
 Sets the appId / userId combination to be used to configure the SPInterstitialClient instance. If you are using only an appId or a single combination of appId / userId then you don't need to call this method. If you have already obtained a reference to the SPInterstitialClient instance (via the interstitialClient method) calling this method will have no effect, as the instance will have been configured with the credentials used to start the SDK for the first time.

 @param credentialsToken The credentials string token returned by a previous invocation of the SDK start method whose appId and userId will be configured in the returned SPInterstitialClient instance. If you pass an invalid credentials token, this method will throw an exception.

 @see startForAppId:userId:securityToken:
 @see startWithAutogeneratedUserForAppId:securityToken:
 @see interstitialClient
 */

+ (void)setCredentialsForInterstitial:(NSString *)credentials;

/** @name Setting the currency name **/

/** Sets the name of your virtual currency.

 @param name This is a human readable, descriptive name of your virtual currency.
 */
+ (void)setCurrencyName:(NSString *)name;

+ (void)setCurrencyName:(NSString *)name forCredentials:(NSString *)credentialsToken;

+ (NSString *)currencyNameForCredentials:(NSString *)credentialsToken;

/** @name Determining if notifications should be shown to the user **/

/** Whether the SDK should show a toast-like notification to the user the first time calling [SPVirtualCurrencyServerConnector fetchDeltaOfCoins] after completing an engagement returns a non-zero value.

 An example notification would be @"Congratulations! You've earned XXX coins!!", where 'coins' would be your currency name.

 @param shouldShowNotification Default value is YES.

 @see setShowPayoffNotificationOnVirtualCoinsReceived:forCredentials:
 @see setCurrencyName:
 @see [SPVirtualCurrencyServerConnector fetchDeltaOfCoins]
 */
+ (void)setShowPayoffNotificationOnVirtualCoinsReceived:(BOOL)shouldShowNotification;

+ (void)setShowPayoffNotificationOnVirtualCoinsReceived:(BOOL)shouldShowNotification
                                         forCredentials:(NSString *)credentialsToken;

+ (BOOL)shouldShowPayoffNotificationOnVirtualCoinsReceivedForCredentials:(NSString *)credentialsToken;

/** @name Accessing the Virtual Currency Server */

/**
 Returns an SPVirtualCurrencyServerConnector instance configured with the appId, userId and securityToken passed in a previous invocation of the SDK start method

 @return An instance of SPVirtualCurrencyServerConnector configured with the appId, userId and securityToken provided previously to the SDK start method.

 @see requestDeltaOfCoinsNotifyingDelegate:

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use the Virtual Currency Server with more than one appId - userId combination, refer to VCSConnectorForCredentials: instead.
 */
+ (SPVirtualCurrencyServerConnector *)VCSConnector;

/**
 Returns an SPVirtualCurrencyServerConnector instance configured with the appId, userId and securityToken passed in a previous invocation of the SDK start method

 @param credentialsToken The credentials string token returned by a previous invocation of the SDK start method whose appId, userId and securityToken will be configured in the returned SPVirtualCurrencyServerConnector instance. If you pass an invalid credentials token, this method will throw an exception.

 @return An instance of SPVirtualCurrencyServerConnector configured with the appId, userId and securityToken corresponding to the provided credentials token.
 */
+ (SPVirtualCurrencyServerConnector *)VCSConnectorForCredentials:(NSString *)credentialsToken;

/**
 Requests to SponsorPay's Virtual Currency Server the amount of coins earned by the user since the last check, notifying the provided delegate of the result.

 @param delegate Any object conforming to the SPVirtualCurrencyConnectionDelegate, which will be notified of the result of the request.

 @return The instance of SPVirtualCurrencyServerConnector that is being used to access SponsorPay's Virtual Currency Server for this request.

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use the Virtual Currency Server with more than one appId - userId combination, refer to VCSConnectorForCredentials: instead.
 */
+ (SPVirtualCurrencyServerConnector *)requestDeltaOfCoinsNotifyingDelegate:(id<SPVirtualCurrencyConnectionDelegate>)delegate;

/** @name Reporting Rewarded Actions as completed */

/**
 Reports a Rewarded Action ID as completed to the SponsorPay servers.

 @param actionID The ID of the action to report as completed.

 @warning Action IDs can only contain capital letters, numbers, and the underscore (_) sign. If your action ID is not correctly formatted this method will throw an exception.

 @warning This method expects that you've started the SDK with a single appId - userId combination during the current session, or run, of your app. If you've not started the SDK yet or you've done it more than once with different appId - userId combinations, this method will throw an exception. If you need to use the SDK with ore than one appId - userId combination, refer to reportActionCompleted:forCredentials: instead.
 */
+ (void)reportActionCompleted:(NSString *)actionID;

/**
 Reports a Rewarded Action ID as completed to the SponsorPay servers, using the appId corresponding to the passed credentials token.

 @param actionID The ID of the action to report as completed.

 @param credentialsToken The credentials string token returned by a previous invocation of the SDK start method. The corresponding appId will be used to perform this request. If you pass an invalid credentials token, this method will throw an exception.
*/
+ (void)reportActionCompleted:(NSString *)actionID forCredentials:(NSString *)credentialsToken;

/** @name Accessing the Singleton Instance */

+ (SponsorPaySDK *)instance;

/**
 Validates if a credential token is valid. A credential token is valid after the SDK was started using the corrensponding appId/userId pair

 @param credentialsToken The credentials to be evaluated

 @return YES if the credentialsToken is valid. Otherwise it returns NO.
 */
+ (BOOL)isCredentialsTokenValid:(NSString *)credentialsToken;

/**
 Returns the version of the SDK.

 @return The string containing the version of the SDK.
 */
+ (NSString *)versionString;

@end

/**
 */
FOUNDATION_EXPORT NSString *const SPCurrencyNameChangeNotification;

/**
 */
FOUNDATION_EXPORT NSString *const SPNewCurrencyNameKey;

/**
 */
FOUNDATION_EXPORT NSString *const SPAppIdKey;

/**
 */
FOUNDATION_EXPORT NSString *const SPUserIdKey;
