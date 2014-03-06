//
//  SPInterstitialOffer.m
//  SponsorPayTestApp
//
//  Created by David Davila on 27/10/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialOffer.h"

@implementation SPInterstitialOffer

- (instancetype)initWithNetworkName:(NSString *)name
                               adId:(NSString *)adId
                      arbitraryData:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.networkName = name;
        self.adId = adId;
        self.arbitraryData = dictionary;
    }
    return self;
}

+ (instancetype)offerWithNetworkName:(NSString *)name
                                adId:(NSString *)adId
                       arbitraryData:(NSDictionary *)dictionary
{
    return [[self alloc] initWithNetworkName:name adId:adId arbitraryData:dictionary];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Network: %@ - Ad id: @ - Data: %@", self.networkName, self.arbitraryData];
}

@end
