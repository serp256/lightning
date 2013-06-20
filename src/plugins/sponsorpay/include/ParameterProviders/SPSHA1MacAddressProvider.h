//
//  SPSHA1MacAddressProvider.h
//  SponsorPaySample
//
//  Created by David Davila on 11/1/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPMacAddressProvider.h"

@interface SPSHA1MacAddressProvider : SPMacAddressProvider <SPURLParametersProvider>

@property (readonly) NSString *macAddressSHA1;

@end