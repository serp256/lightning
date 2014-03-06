//
//  SPAdvertisementViewControllerSubclass.h
//  SponsorPay iOS SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPAdvertisementViewController.h"

typedef void (^SPViewControllerDisposalBlock)(void);

@interface SPAdvertisementViewController (SDKPrivate)

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *userId;
@property (readwrite, strong, nonatomic) NSString *currencyName;
@property (copy) SPViewControllerDisposalBlock disposalBlock;

- (id)initWithUserId:(NSString *)userId
               appId:(NSString *)appId
       disposalBlock:(SPViewControllerDisposalBlock)disposalBlock;

@end
