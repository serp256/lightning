//
//  SPInterstitialViewController.h
//  SponsorPay iOS SDK
//
//  Copyright 2011 SponsorPay. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SPAdvertisementViewController.h"

typedef enum {
    NOT_WAITING,
    WAITING_FOR_INITIAL_REQUEST_RESPONSE,
    WAITING_FOR_WEBVIEW_TO_LOAD_INITIAL_CONTENTS
} SPInterstitialRequestStatus;

typedef enum {
	AD_SHOWN,
	NO_INTERSTITIAL_AVAILABLE,
    ERROR_NETWORK,
    ERROR_TIMEOUT,
    CLOSED
} SPInterstitialViewControllerStatus;

@class SPInterstitialViewController;

/**
 The SPInterstitialViewControllerDelegate protocol is to be implemented by classes that wish to be notified of the availability of Interstitial offers from the SponsorPay platform and status changes in the lifecycle of SPInterstitialViewControllerDelegate.
 */
@protocol SPInterstitialViewControllerDelegate <NSObject>

@required
/**
 Sent when the corresponding SPInterstitialViewControllerDelegate changes status, denoting an answer from the server which indicates the availability of an Interstitial offer, a close event, or an error.
 
 @param interstitialViewController The SPInterstitialViewController which is sending this message.
 @param status A status code defined in SPInterstitialViewControllerStatus.
 */
- (void)interstitialViewController:(SPInterstitialViewController *)interstitialViewController
                   didChangeStatus:(SPInterstitialViewControllerStatus)status;

@end


/**
 SPInterstitialViewController is a subclass of SPAdvertisementViewController that requests and shows SponsorPay's Mobile Interstitial.
 
 In order to present itself it requires that you pass to it an instance of one of your own UIViewController subclasses that will act as the OfferWall parent. @see startLoadingWithParentViewController:
 
 It will notify its delegate of events in the lifecycle of the interstitial, including when no offers are available and when a shown interstitial is closed. @see SPInterstitialViewControllerDelegate.
 */
@interface SPInterstitialViewController : SPAdvertisementViewController

/**
 Delegate conforming to the SPInterstitialViewControllerDelegate protocol that will be notified of events in the lifecycle of the interstitial, including when no offers are available and when a shown interstitial is closed.
 */
@property (nonatomic, assign) id<SPInterstitialViewControllerDelegate> delegate;

/**
 User defined skin name to customize the appearance of the shown offer.
 */
@property (nonatomic, retain) NSString *skin;

/**
 URL of a background image to customize the appearance of the shown offer.
 */
@property (nonatomic, retain) NSString *backgroundImageUrl;

/**
 Time to wait for a requested offer to arrive before giving up.
 */
@property (assign) NSTimeInterval loadingTimeout;

/**
 This initializer has been deprecated and will be removed from a future SDK release. Please don't initialize this class directly, rather access it through [SponsorPaySDK interstitialViewController] or [SponsorPaySDK interstitialViewControllerForCredentials:]
 */
- (id)initWithUserId:(NSString *)userId appId:(NSString *)appId __deprecated;

/**
 This initializer has been deprecated and will be removed from a future SDK release. Please don't initialize this class directly, rather access it through [SponsorPaySDK interstitialViewController] or [SponsorPaySDK interstitialViewControllerForCredentials:]
 */
- (id)initWithUserId:(NSString *)theUserId
               appId:(NSString *)theAppId
       backgroundUrl:(NSString *)theBackgroundUrl
                skin:(NSString *)theSkinName __deprecated;

/**
 This initializer has been deprecated and will be removed from a future SDK release. Please don't initialize this class directly, rather access it through [SponsorPaySDK interstitialViewController] or [SponsorPaySDK interstitialViewControllerForCredentials:]
 */
- (id)initWithUserId:(NSString *)theUserId
               appId:(NSString *)theAppId
       backgroundUrl:(NSString *)theBackgroundUrl
                skin:(NSString *)theSkinName
      loadingTimeout:(NSTimeInterval)loadingTimeOut __deprecated;

/**
 Please don't initialize this class directly, rather access it through [SponsorPaySDK interstitialViewController] or [SponsorPaySDK interstitialViewControllerForCredentials:]
 */
- (id)init;


/**
 Attempts to load and, if available, presents the SponsorPay Interstitial as a child view controller of your own view controller. 
 
 @param parentVC An instance of your own UIViewController subclass that will be used as the parent view controller of the presented Interstitial.
 */
- (void)startLoadingWithParentViewController:(UIViewController *)parentVC;

/**
 Cancels a pending request for interstitial offer. If the answer has been already received and the Interstitial is being displayed this call will have no effect. In this case please use [SPAdvertisementViewController dismissAnimated:] instead.
 
 @return Whether this invocation resulted in a canceled request.
 */
- (BOOL)cancelInterstitialRequest;

+ (void)overrideBaseURLWithURLString:(NSString *)newUrl;
+ (void)restoreBaseURLToDefault;

@end
