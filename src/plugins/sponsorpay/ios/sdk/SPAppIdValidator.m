//
//  SPAppIdValidator.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/26/11.
//  Copyright (c) 2011 SponsorPay. All rights reserved.
//

#import "SPAppIdValidator.h"

NSString *const SPInvalidAppIdException = @"SPInvalidAppIdException";
@implementation SPAppIdValidator

+ (void)validateOrThrow:(NSString *)appId;
{
    if (!appId.length || [appId isEqualToString:@"0"]) {
        NSString *invalidAppIdReason = [NSString stringWithFormat:
                                        @"A valid App ID must be specified ('%@' was provided)", appId];
        
        [NSException raise:SPInvalidAppIdException format:@"%@", invalidAppIdReason];
    }
}

@end
