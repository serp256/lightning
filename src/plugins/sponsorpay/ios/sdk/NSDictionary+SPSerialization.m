//
//  NSDictionary+SPSerialization.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 18/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "NSDictionary+SPSerialization.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSDictionary_SPSerialization);

@implementation NSDictionary (SPSerialization)

- (NSString *)SPComponentsJoinedBy:(NSString *)entrySeparator
                 keyValueSepator:(NSString *)keyValueSeparator
{
    __block NSMutableString *serializedString = [[NSMutableString alloc] init];
    NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [sortedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [serializedString appendString:[NSString stringWithFormat:@"%@ %@ '%@'", obj, keyValueSeparator, self[obj]]];
        } else {
            [serializedString appendString:[NSString stringWithFormat:@"%@ %@ %@ '%@'", entrySeparator, obj, keyValueSeparator, self[obj]]];
        }
    }];

    return serializedString;
}

- (NSString *)SPComponentsJoined
{
    return [self SPComponentsJoinedBy:@"," keyValueSepator:@":"];
}

@end
