//
//  SPInterstitialClient_SDKPrivate.h
//  SponsorPayTestApp
//
//  Created by David Davila on 01/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPInterstitialClient.h"

@interface SPInterstitialClient (SDKPrivate)

@property (readonly, nonatomic, assign) BOOL didSetCredentials;

+ (instancetype)sharedClient;

- (BOOL)setAppId:(NSString *)appId userId:(NSString *)userId;
- (void)clearCredentials;

@end
