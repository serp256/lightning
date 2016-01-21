//
//  TQDQuickDialogController.h
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-18.
//
//

#import "QuickDialogController.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface TQDQuickDialogController : QuickDialogController

+ (TQDQuickDialogController *)controllerForName:(NSString *)name;

- (TencentOAuth *)tencentOAuth;
- (void)accessTokenChanged:(NSString *)newValue;

- (void)responseDidReceived:(APIResponse*)response forMessage:(NSString *)message;

@end
