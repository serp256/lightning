//
//  SPNetworkOperation.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 11/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPNetworkOperation : NSOperation
@property (assign) BOOL didRequestSucceed;
@property (assign) int httpStatusCode;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, strong) NSURL *url;
@end
