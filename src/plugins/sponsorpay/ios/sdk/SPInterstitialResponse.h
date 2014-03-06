//
//  SPInterstitialResponseProcessor.h
//  SponsorPayTestApp
//
//  Created by David Davila on 27/10/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPInterstitialResponse : NSObject

@property (readonly, assign, nonatomic) BOOL isSuccessResponse;
@property (readonly, strong, nonatomic) NSError *error;
@property (readonly, strong, nonatomic) NSArray *orderedOffers;

+ (instancetype)responseWithURLResponse:(NSURLResponse *)response
                                   data:(NSData *)data
                        connectionError:(NSError *)connectionError;


@end
