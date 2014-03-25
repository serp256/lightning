//
//  SPEventHub.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Managing Sponsorpay events and notifications related to interstitials.
 * This class listens for the notifications on SPInterstitialEventNotification and fires a request to the tracker engine.
 */
@interface SPInterstitialEventHub : NSObject
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *userId;

// Override URLs - Remove these methods before performing a release
- (void)overrideBaseURLWithURLString:(NSString *)newURLString;
- (void)restoreBaseURLToDefault;
@end
