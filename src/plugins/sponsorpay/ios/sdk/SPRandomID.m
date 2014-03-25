//
//  SPRandomID.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import "SPRandomID.h"

@implementation SPRandomID

+ (NSString *)randomIDString
{
    NSString *generatedRandomID = nil;

    Class uuidClass = NSClassFromString(@"NSUUID");
    if (uuidClass) {
        id uuidInstance = [[uuidClass alloc] init];
        generatedRandomID = [uuidInstance performSelector:@selector(UUIDString)];
    } else {
        static NSString *const alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        static const NSUInteger randomStringLength = 64;

        NSMutableString *randomString = [NSMutableString stringWithCapacity:randomStringLength];

        for (int i=0; i<randomStringLength; i++) {
            [randomString appendFormat: @"%C", [alphabet characterAtIndex: arc4random() % [alphabet length]]];
        }

        generatedRandomID = randomString;
    }

    return generatedRandomID;
}

@end
