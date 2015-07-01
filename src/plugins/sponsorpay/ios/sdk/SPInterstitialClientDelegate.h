//
//  SPInterstitialClientDelegate.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPInterstitialClient;

/**
 *  Defines selectors that a delegate of SPInterstitialClient can implement for being notified of offers availability and the state of the interstitial.
 */
@protocol SPInterstitialClientDelegate<NSObject>

/** Called in your delegate instance to deliver the answer relaed to the checkInterstitialAvailable request.
 @param client The SPInterstitialClient delivering this answer.
 @param canShowInterstitial Whether an interstitial ad can be shown at this time.
 */
- (void)interstitialClient:(SPInterstitialClient *)client canShowInterstitial:(BOOL)canShowInterstitial;

/** Called in your delegate instance to notify that an interstitial is being shown.
 @param client The SPInterstitialClient delivering this answer.
 */
- (void)interstitialClientDidShowInterstitial:(SPInterstitialClient *)client;

/** Called in your delegate instance to notify that an interstitial is being dismissed.
 @param client The SPInterstitialClient delivering this answer.
 @param dismissReason One of the values defined in the SPInterstitialDismissReason enum corresponding to the condition that caused dismissal of the interstitial.
 */
- (void)interstitialClient:(SPInterstitialClient *)client didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason;

/** Called in your delegate instance to notify of an error condition.
 @param client The SPInterstitialClient delivering this answer.
 @param error An NSError instance enclosing more information about the error.
 */
- (void)interstitialClient:(SPInterstitialClient *)client didFailWithError:(NSError *)error;

@end
