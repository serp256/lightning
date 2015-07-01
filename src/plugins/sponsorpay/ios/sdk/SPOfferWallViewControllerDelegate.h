//
//  SPOfferWallViewControllerDelegate.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPOfferWallStatus.h"

@class SPOfferWallViewController;

/**
 The SPOfferWallViewControllerDelegate protocol is to be implemented by classes that wish to be notified when a
 presented SPOfferWallViewControllerDelegate is dismissed.
 */
@protocol SPOfferWallViewControllerDelegate<NSObject>

/**
 Sent when the SPOfferWallViewController finished. It can have been explicitly dismissed by the user, closed itself when
 redirecting outside of the app to proceed with an offer, or closed due to an error.

 @param offerWallVC the SPOfferWallViewController which is being closed.
 @param status if there was a network error, this will have the value of SPONSORPAY_ERR_NETWORK.
 */
@optional
- (void)offerWallViewController:(SPOfferWallViewController *)offerWallVC isFinishedWithStatus:(int)status;

@end
