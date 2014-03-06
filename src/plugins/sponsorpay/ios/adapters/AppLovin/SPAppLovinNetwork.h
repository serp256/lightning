//
//  SPProviderAppLovin.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 09/01/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPBaseNetwork.h"

@interface SPAppLovinNetwork : SPBaseNetwork
@property (nonatomic, copy, readonly) NSString *apiKey;
@end
