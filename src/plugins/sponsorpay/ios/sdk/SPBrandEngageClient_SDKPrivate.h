//
//  SPBrandEngageClient_SDKPrivate.h
//  SponsorPay iOS SDK
//
//  Copyright 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageClient.h"

@interface SPBrandEngageClient (SDKPrivate)

@property (readwrite, retain, nonatomic) NSString *appId;
@property (readwrite, retain, nonatomic) NSString *userId;
@property (readwrite, retain, nonatomic) NSString *currencyName;

@end
