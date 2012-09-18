// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import <Foundation/Foundation.h>
#import "TJCCoreFetcherHandler.h"

@interface TJCEventTrackingRequestHandler : TJCCoreFetcherHandler<TJCWebFetcherDelegate>
{
    
}

/*!	\fn initRequestWithDelegate:andRequestTag:(id<TJCFetchResponseDelegate> aDelegate, int aTag)
 *	\brief Initializes the #TJCEventTrackingRequestHandler object with the given delegate and tag id.
 *
 *	\param aDelegate The #TJCFetchResponseDelegate delegate object to initialize with.
 *	\return The #TJCEventTrackingRequestHandler object.
 */
- (id)initRequestWithDelegate:(id<TJCFetchResponseDelegate>)aDelegate andRequestTag:(int)aTag;

/*!	\fn sendIAPEventWithName:(NSString*)name andPrice:(int)price
 *	\brief Initiates the URL request to track an In-App-Purchase (IAP) event.
 *
 *	\param name The name of the In-App-Purchase (IAP) item that this event should track.
 *	\param price The amount that the item was sold for.
 *	\param quantity The number of items for this purchase.
 *	\param currencyCode The currency code, such as USD.
 *	\return n/a
 */
- (void)sendIAPEventWithName:(NSString*)name price:(float)price quantity:(int)quantity currencyCode:(NSString*)currencyCode;

@end
