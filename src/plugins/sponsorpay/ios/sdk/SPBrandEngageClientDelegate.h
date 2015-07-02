//
//  SPBrandEngageClientDelegate.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPBrandEngageClientStatus.h"

@class SPBrandEngageClient;
@protocol SPVirtualCurrencyConnectionDelegate;

/** 
 *  Defines selectors that a delegate of SPBrandEngageClient can implement for being notified of offers availability and engagement status.
 */
@protocol SPBrandEngageClientDelegate<NSObject>

/** @name Requesting offers */

/** Sent when BrandEngage receives an answer about offers availability.

@param brandEngageClient The instance of SPBrandEngageClient that sent this message.
@param areOffersAvailable A boolean value indicating whether offers are available. If this value is YES, you can start the engagement.
*/
- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient didReceiveOffers:(BOOL)areOffersAvailable;

/** @name Showing offers */

/** Sent when a running engagement changes state.

@param brandEngageClient The instance of SPBrandEngageClient that sent this message.
@param newStatus A constant value of the SPBrandEngageClientStatus type indicating the new status of the engagement.
*/

- (void)brandEngageClient:(SPBrandEngageClient *)brandEngageClient didChangeStatus:(SPBrandEngageClientStatus)newStatus;


@end
