//
//  SPVirtualCurrencyConnector.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2011 SponsorPay. All rights reserved.
//

#import "SPVirtualCurrencyConnectionDelegate.h"

@class SPVirtualCurrencyServerConnector;

/* Handler that can be run when a successful answer to the delta of coins request (fetchDeltaOfCoins) is received.
 
 @param removeAfterExecuting A reference to a Boolean value. The block can set the value to YES if the block must run only once and be removed after it's called for the first time. This is useful to register a handler that will be run only on the next successful VCS callback, and ont on subsequent ones. This is an out-only argument. You should only ever set this Boolean to YES within the block.
 
 @see addFetchDeltaOfCoinsCompletionBlock

 */
typedef void (^SPVCSDeltaOfCoinsRequestCompletionBlock)(double deltaOfCoins,
                                                        NSString *latestTransactionId,
                                                        BOOL *removeAfterExecuting);


/**
 The SPVirtualCurrencyServerConnector class provides functionality to query SponsorPay's Virtual Currency Servers to obtain the number of virtual coins the user has earned.
 
 It keeps track of the last time the amount of earned coins was requested for a given user, reporting newly earned amounts between successive requests, even across application sessions.
 
 The client is authenticated to the virtual currency server by signing URL requests with the secret token or key that SponsorPay has assigned to your publisher account, and that you must provide when initializing the SDK (@see SponsorPaySDK).
 
 Answers to the requests are asynchronously reported to your registered delegate through the selectors defined in the SPVirtualCurrencyConnectionDelegate protocol.
 */
@interface SPVirtualCurrencyServerConnector : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/** @name Obtaining the last transaction ID */

/** Latest transaction ID for your user and app IDs, as reported by the server.
 This is used to keep track of new transactions between invocations to fetchDeltaOfCoins.
 */
@property (nonatomic, copy) NSString *latestTransactionId;

/** @name Being notified asyncronously of server responses and errors */

/** Delegate to be notified of answers to requests and error conditions.
 Answers to the requests are asynchronously reported to your registered delegate through the selectors defined in the SPVirtualCurrencyConnectionDelegate protocol.
*/
@property (weak) id<SPVirtualCurrencyConnectionDelegate> delegate;

/** Adds a completion handler that will be run when a successful answer to fetchDeltaOfCoins is received.
  
 Though you could use this method to obtain the same functionality that registering a SPVirtualCurrencyConnectionDelegate offers for being notified of the amount of coins earned by the user, relying on the delegate is the recommended way of being notified of the results of the request, as it can handle error conditions.
 
 The supplied handler will be run in the main thread. Multiple completion handlers can be specified in successive calls and they will run in the order in which they were added.
 
 @param completionBlock Block to be run when a successful answer to the delta of coins request is received.
 */
- (void)addFetchDeltaOfCoinsCompletionBlock:(SPVCSDeltaOfCoinsRequestCompletionBlock)completionBlock;

/** Fetches the amount of coins earned since the last time this method was invoked for the current user ID / app ID combination.
 
 This involves a network call which will be performed in the background. When the answer from the server is received, your registered delegate will be notified.
 */
- (void)fetchDeltaOfCoins;

/** Fetches the amount of a given currency earned since the last time this method was invoked for the current user ID / app ID combination.

 This involves a network call which will be performed in the background. When the answer from the server is received, your registered delegate will be notified.

 @param currencyId The currency id that will be fetched. A nil currency fetches the default currency
 */

- (void)fetchDeltaOfCoinsWithCurrencyId:(NSString *)currencyId;

@end

FOUNDATION_EXPORT NSString *const SPVCSPayoffReceivedNotification;
FOUNDATION_EXPORT NSString *const SPVCSPayoffAmountKey;
FOUNDATION_EXPORT NSString *const SPVCSCurrencyName;
