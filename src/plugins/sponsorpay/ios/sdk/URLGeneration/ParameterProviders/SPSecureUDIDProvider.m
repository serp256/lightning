//
//  SPSecureUDIDProvider.m
//  SponsorPaySample
//
//  Created by David Davila on 11/1/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPSecureUDIDProvider.h"
#import "SecureUDID.h"

static NSString *const kSPURLParamKeySecureUDID = @"secureudid";

static NSString *const kSPSecureUDIDDomain = @"com.sponsorpay.sdk";
static NSString *const kSPSecureUDIDKey = @"WHX9h4Gc4FNR78IlUPLtBqYfyf1QygszrKbgnQmsBRpKaKjH6ZdEKN94Wo40hbQ";

@implementation SPSecureUDIDProvider

- (NSDictionary *)dictionaryWithKeyValueParameters {
    return [NSDictionary dictionaryWithObject:[SecureUDID UDIDForDomain:kSPSecureUDIDDomain
                                                               usingKey:kSPSecureUDIDKey]
                                       forKey:kSPURLParamKeySecureUDID];
}

@end
