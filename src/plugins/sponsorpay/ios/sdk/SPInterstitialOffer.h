//
//  SPInterstitialOffer.h
//  SponsorPayTestApp
//
//  Created by David Davila on 27/10/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPInterstitialOffer : NSObject

@property (strong, nonatomic) NSString *networkName;
@property (strong, nonatomic) NSString *adId;
@property (strong, nonatomic) NSDictionary *arbitraryData;

+ (instancetype)offerWithNetworkName:(NSString *)name
                                adId:(NSString *)adId
                       arbitraryData:(NSDictionary *)dictionary;

@end
