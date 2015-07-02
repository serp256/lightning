//
//  SPOfferWallViewController.h
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SPOfferWallViewControllerDelegate.h"


#define SPONSORPAY_ERR_NETWORK -1

/**
 *  Block called on dismiss of the OfferWall
 *
 *  @param status The status of the OfferWall when dismissed. Its value is one if dismissed by the user or -1 if dismissed because of a network error
 */
typedef void (^OfferWallCompletionBlock)(int status);


@class SPCredentials;

/**
 *  Value to return as status on [SPOfferWallViewControllerDelegate offerWallViewController:isFinishedWithStatus:]
 *  when there is a network error.
 */
@class SPOfferWallViewController;

/**
 SPOfferWallViewController is a subclass of SPAdvertisementViewController that requests and shows SponsorPay's Mobile
 OfferWall.

 In order to present itself it requires that you pass to it an instance of one of your own UIViewController subclasses
 that will act as the OfferWall parent. @see showOfferWallWithParentViewController:

 It will notify its delegate when it's closed. @see SPOfferWallViewControllerDelegate.
 */
@interface SPOfferWallViewController : UIViewController

/**
 Delegate conforming to the SPOfferWallViewControllerDelegate protocol that will be notified when the OfferWall is
 closed.
 */
@property (nonatomic, weak) id<SPOfferWallViewControllerDelegate> delegate;

/**
 If set to YES, this View Controller will be automatically dismissed when the user clicks on an offer and is redirected
 outside the app.
*/
@property (readwrite) BOOL shouldFinishOnRedirect;

/** Name of your virtual currency.
 This is a human readable, descriptive name of your virtual currency.
 */
@property (nonatomic, copy, readonly) NSString *currencyName;

/**
 * The ID of the placement
 */
@property (nonatomic, copy) NSString *placementId;

/**
 A dictionary of arbitrary key / value strings to be provided to the SponsorPay platform when requesting the
 advertisement.
 */
@property (nonatomic, strong) NSDictionary *customParameters;

/**
 *  Sets if the close button will be displayed while the Offer Wall is loading.
 *
 *  @warning This property is not evaluated if the key SPOFWShowCloseOnLoad is set in the Info file.
 */
@property (nonatomic, assign) BOOL showCloseButtonOnLoad;

/**
 Please don't initialize this class directly, rather access it through [SponsorPaySDK offerWallViewController] or
 [SponsorPaySDK offerWallViewControllerForCredentials:]
 */
- (id)initWithCredentials:(SPCredentials *)credentials;

/**
 Presents the SponsorPay Mobile OfferWall as a child view controller of your own view controller.

 @param parentViewController An instance of your own UIViewController subclass that will be used as the parent view
 controller of the presented OfferWall.
 */
- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController;

/**
 *  @param placementId     The id of the placement
 */
- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController placementId:(NSString *)placementId;


/**
 Presents the SponsorPay Mobile OfferWall as a child view controller of your own view controller.

 @param parentViewController An instance of your own UIViewController subclass that will be used as the parent view
 controller of the presented OfferWall.
 */
- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController
                                   completion:(OfferWallCompletionBlock)block;

/**
 *  @param placementId     The id of the placement
 */
- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController
                                  placementId:(NSString *)placementId
                                   completion:(OfferWallCompletionBlock)block;

@end
