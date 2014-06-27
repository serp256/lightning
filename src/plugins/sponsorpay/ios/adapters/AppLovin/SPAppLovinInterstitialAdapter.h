//
//  SPAppLovingInterstitialAdapter.h
//  SponsorPayTestApp
//
//  Created by David Davila on 01/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPInterstitialNetworkAdapter.h"
#import "ALSdk.h"

@class SPAppLovinNetwork;

@interface SPAppLovinInterstitialAdapter : NSObject <SPInterstitialNetworkAdapter, ALAdLoadDelegate, ALAdDisplayDelegate>

@property (weak, nonatomic) SPAppLovinNetwork *network;

@end
