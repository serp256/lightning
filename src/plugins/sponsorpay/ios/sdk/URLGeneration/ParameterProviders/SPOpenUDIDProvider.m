//
//  SPOpenUDIDProvider.m
//  SponsorPaySample
//
//  Created by David Davila on 11/1/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPOpenUDIDProvider.h"
#import "OpenUDID.h"

static NSString *const kSPURLParamKeyOpenUDID = @"openudid";

@implementation SPOpenUDIDProvider

- (NSDictionary *)dictionaryWithKeyValueParameters {
    @synchronized ([OpenUDID class]) {
        return [NSDictionary dictionaryWithObject:[OpenUDID value] forKey:kSPURLParamKeyOpenUDID];
    }
}

@end
