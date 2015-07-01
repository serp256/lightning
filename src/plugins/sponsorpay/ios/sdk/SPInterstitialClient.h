//
//  SPInterstitialClient.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialNetworkAdapter.h"
#import "SPInterstitialClientDelegate.h"

@class SPCredentials;

/**
 *  Used as the domain for the NSError instances enclosing errors triggered by the SponsorPay interstitial client
 */
extern NSString *const SPInterstitialClientErrorDomain;

/**
 *  Error code corresponding to the "Cannot instantiate 3rd party SDK adapter" error condition
 */
extern const NSInteger SPInterstitialClientCannotInstantiateAdapterErrorCode;

/**
 *  Dictionary key used to access the loggable error description (non localized, in English) of the userInfo dictionary included in errors triggered by the SponsorPay interstitial client
 */
extern NSString *const SPInterstitialClientErrorLoggableDescriptionKey;


/**
 *  The SponsorPay interstitial client manages the mediation of interstitial providing SDKs and the initialization - requesting interstitial - showing interstitial - notification of events flow. This is a singleton
 */
@interface SPInterstitialClient : NSObject<SPInterstitialNetworkAdapterDelegate>

/**
 *  The ID of the placement
 */
@property (nonatomic, copy) NSString *placementId;

/**
 *  Your delegate instance which will be notified of interstitial availability, events and errors
 */
@property (nonatomic, weak) id<SPInterstitialClientDelegate> delegate;

/**
 *  The user credentials used to configure this interstitial client instance
 */
@property (nonatomic, strong, readonly) SPCredentials *credentials;

/**
 *  Checks if an interstitial ad is available. The answer will be delivered asynchronously to your delegate's interstitialClient:canShowInterstitial: selector.
 */
- (void)checkInterstitialAvailable;

/**
 *  Checks if an interstitial ad is available. The answer will be delivered asynchronously to your delegate's interstitialClient:canShowInterstitial: selector.
 *
 *  @param placementId The ID of the ad placement
 */
- (void)checkInterstitialAvailableForPlacementId:(NSString *)placementId;

/**
 *  Shows an interstitial ad. Check first that one is ready to be shown with checkInterstitialAvailable.
 *
 *  @param parentViewController View controller on top of which the interstitial will be shown. Some of the underlying SDKs attach the interstitial directly to the application's window or access the app's view hierarchy in other ways. Therefore this parameter is not guaranteed to be used.
 *
 *  @see checkInterstitialAvailable
 */
- (void)showInterstitialFromViewController:(UIViewController *)parentViewController;

@end
