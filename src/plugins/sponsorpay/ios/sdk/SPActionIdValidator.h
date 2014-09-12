//
//  SPActionIdValidator.h
//  SponsorPay iOS SDK
//
//  Created by David Davila on 12/6/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const SPInvalidActionIdException;

@interface SPActionIdValidator : NSObject

+ (BOOL)validate:(NSString *)actionId reasonForInvalid:(NSString **)reason;

+ (void)validateOrThrow:(NSString *)actionId;

@end
