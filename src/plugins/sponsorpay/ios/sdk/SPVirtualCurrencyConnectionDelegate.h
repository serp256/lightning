//
//  SPVirtualCurrencyServerConnectorDelegate.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SPVirtualCurrencyRequestErrorType.h"

@class SPVirtualCurrencyServerConnector;

/** 
 *  Defines selectors that a delegate of SPVirtualCurrencyServerConnector can implement for being notified of answers to requests and triggered errors.
 */
@protocol SPVirtualCurrencyConnectionDelegate<NSObject>
@required

/** Sent when SPVirtualCurrencyServerConnector receives an answer from the server for the amount of coins newly earned by the user.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param deltaOfCoins Amount of coins earned by the user.
 @param currencyName The name of the currency being earned by the user
 @param transactionId Transaction ID of the last known operation involving your virtual currency for this user.
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
  didReceiveDeltaOfCoinsResponse:(double)deltaOfCoins
                      currencyId:(NSString *)currencyId
                    currencyName:(NSString *)currencyName
             latestTransactionId:(NSString *)transactionId;


/** Sent when SPVirtualCurrencyServerConnector detects an error condition.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param error Type of the triggered error. @see SPVirtualCurrencyRequestErrorType
 @param errorCode if this is an error received from the back-end, error code as reported by the server.
 @param errorMessage if this is an error received from the back-end, error message as reported by the server.
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
                 failedWithError:(SPVirtualCurrencyRequestErrorType)error
                       errorCode:(NSString *)errorCode
                    errorMessage:(NSString *)errorMessage;

@optional
/** Sent when SPVirtualCurrencyServerConnector receives an answer from the server for the amount of coins newly earned by the user.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param deltaOfCoins Amount of coins earned by the user.
 @param currencyName The name of the currency being earned by the user
 @param transactionId Transaction ID of the last known operation involving your virtual currency for this user.

 @deprecated Since version 7.1.0. Use virtualCurrencyConnector:didReceiveDeltaOfCoins:currencyName:latestTransactionId
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
  didReceiveDeltaOfCoinsResponse:(double)deltaOfCoins
                    currencyName:(NSString *)currencyName
             latestTransactionId:(NSString *)transactionId DEPRECATED_MSG_ATTRIBUTE("This method is deprecated. Please use virtualCurrencyConnector:didReceiveDeltaOfCoins:currencyId:currencyName:latestTransactionId");

/** Sent when SPVirtualCurrencyServerConnector receives an answer from the server for the amount of coins newly earned by the user.
 @param connector SPVirtualCurrencyServerConnector instance of SPVirtualCurrencyServerConnector that sent this message.
 @param deltaOfCoins Amount of coins earned by the user.
 @param transactionId Transaction ID of the last known operation involving your virtual currency for this user.

 @see virtualCurrencyConnector:didReceiveDeltaOfCoins:currencyName:latestTransactionId

 @deprecated Since version 6.5.0. Use virtualCurrencyConnector:didReceiveDeltaOfCoins:currencyName:latestTransactionId
 */
- (void)virtualCurrencyConnector:(SPVirtualCurrencyServerConnector *)connector
  didReceiveDeltaOfCoinsResponse:(double)deltaOfCoins
             latestTransactionId:(NSString *)transactionId DEPRECATED_MSG_ATTRIBUTE("This method is deprecated. Please use virtualCurrencyConnector:didReceiveDeltaOfCoins:currencyId:currencyName:latestTransactionId");

@end
