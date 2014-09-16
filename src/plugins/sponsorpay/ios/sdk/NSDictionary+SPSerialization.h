//
//  NSDictionary+SPSerialization.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 18/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SPSerialization)

- (NSString *)SPComponentsJoinedBy:(NSString *)entrySeparator
                 keyValueSepator:(NSString *)keyValueSeparator;

- (NSString *)SPComponentsJoined;

@end
