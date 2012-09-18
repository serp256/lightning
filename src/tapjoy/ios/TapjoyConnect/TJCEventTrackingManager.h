// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import <Foundation/Foundation.h>
#import "TJCFetchResponseProtocol.h"
#import "TapjoyConnect.h"
#import "TJCTBXML.h"

@class TJCEventTrackingRequestHandler;

@interface TJCEventTrackingManager : NSObject <TJCFetchResponseDelegate>
{
    TJCEventTrackingRequestHandler *eventTrackingSendIAPItems_;
    BOOL waitingForResponse_;	/*!< Indicates whether the client is waiting for a response from the server. Event Tracking methods will not do anything if this is YES. */
}

+ (TJCEventTrackingManager*)sharedTJCEventTrackingManager;

/*!	\fn sendIAPEvent
 *	\brief Initiates the request to POST the IAP data.
 *
 *	\param name The name of the In-App-Purchase (IAP) item that this event should track.
 *	\param price The amount that the item was sold for.
 *	\param quantity The number of items for this purchase.
 *	\param currencyCode The currency code, such as USD.
 *	\return n/a
 */
- (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode;

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
+ (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode;

@end