//
//  SPSystemLogger.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 07/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPSystemLogger.h"

@implementation SPSystemLogger

+ (instancetype)logger
{
    static SPSystemLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPSystemLogger alloc] init];
    });

    return sharedInstance;
}

- (void)logFormat:(NSString *)format arguments:(va_list)arguments
{
    NSLogv(format, arguments);
}

@end
