//
//  QuickDemoViewController.h
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-18.
//
//

#import "QuickDialogController.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface QuickDemoViewController : QuickDialogController

@property (retain, nonatomic) TencentOAuth *tencentOAuth;

+ (QuickDemoViewController *)sharedInstance;

@end
