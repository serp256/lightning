//
//  SPInterstitialClient.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SPInterstitialNetworkAdapter.h"

/** Used as the domain for the NSError instances enclosing errors triggered by the SponsorPay interstitial client */
extern NSString *const SPInterstitialClientErrorDomain;

/** Error code corresponding to the "Cannot instantiate 3rd party SDK adapter" error condition */
extern const NSInteger SPInterstitialClientCannotInstantiateAdapterErrorCode;

/** Dictionary key used to access the loggable error description (non localized, in English) of the userInfo dictionary included in errors triggered by the SponsorPay interstitial client */
NSString *const SPInterstitialClientErrorLoggableDescriptionKey;

@protocol SPInterstitialClientDelegate;

/** The SponsorPay interstitial client manages the mediation of interstitial providing SDKs and the initialization - requesting interstitial - showing interstitial - notification of events flow. This is a singleton
 */
@interface SPInterstitialClient : NSObject <SPInterstitialNetworkAdapterDelegate>

/** Your delegate instance which will be notified of interstitial availability, events and errors */
@property (weak, nonatomic) id<SPInterstitialClientDelegate> delegate;

/** The app ID used to configure this interstitial client instance */
@property (readonly, nonatomic, strong) NSString *appId;

/** The user ID used to configure this interstitial client instance */
@property (readonly, nonatomic, strong) NSString *userId;

/** Checks if an interstitial ad is available. The answer will be delivered asynchronously to your delegate's interstitialClient:canShowInterstitial: selector. */
- (void)checkInterstitialAvailable;

/** Shows an interstitial ad. Check first that one is ready to be shown with checkInterstitialAvailable.
 @param parentViewController View controller on top of which the interstitial will be shown. Some of the underlying SDKs attach the interstitial directly to the application's window or access the app's view hierarchy in other ways. Therefore this parameter is not guaranteed to be used.
 @see checkInterstitialAvailable
 **/
- (void)showInterstitialFromViewController:(UIViewController *)parentViewController;

// TODO: Remove these methods before creating a release
+ (void)overrideBaseURLWithURLString:(NSString *)newURLString eventHub:(NSString *)newEventHubURL;
+ (void)restoreBaseURLToDefault;

@end

@protocol SPInterstitialClientDelegate <NSObject>

/** Called in your delegate instance to deliver the answer relaed to the checkInterstitialAvailable request.
 @param client The SPInterstitialClient delivering this answer.
 @param canShowInterstitial Whether an interstitial ad can be shown at this time.
 */
- (void)interstitialClient:(SPInterstitialClient *)client
       canShowInterstitial:(BOOL)canShowInterstitial;

/** Called in your delegate instance to notify that an interstitial is being shown.
 @param client The SPInterstitialClient delivering this answer.
 */
- (void)interstitialClientDidShowInterstitial:(SPInterstitialClient *)client;

/** Called in your delegate instance to notify that an interstitial is being dismissed.
 @param client The SPInterstitialClient delivering this answer.
 @param reason One of the values defined in the SPInterstitialDismissReason enum corresponding to the condition that caused dismissal of the interstitial.
 */
- (void)interstitialClient:(SPInterstitialClient *)client
    didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason;

/** Called in your delegate instance to notify of an error condition.
 @param client The SPInterstitialClient delivering this answer.
 @param error An NSError instance enclosing more information about the error.
*/
- (void)interstitialClient:(SPInterstitialClient *)client
          didFailWithError:(NSError *)error;

@end

/** Returns a string representation of a SPInterstitialDismissReason enum constant. */
NSString *SPStringFromInterstitialDismissReason(SPInterstitialDismissReason reason);