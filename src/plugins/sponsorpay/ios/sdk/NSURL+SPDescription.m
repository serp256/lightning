//
//  NSURL+SPDescription.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 17/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "NSURL+SPDescription.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(NSURL_SPDescription)

@implementation NSURL (SPDescription)

- (NSString *)SPPrettyDescription
{

    NSString *address = [NSString stringWithFormat:@"%@://%@", [self scheme], [[self host] stringByAppendingPathComponent:[self path]]];
    NSArray *query = [[self.query componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(compare:)];

    return [NSString stringWithFormat:@"\nPath: %@\nQueryString: \n%@", address, query];
}

@end
