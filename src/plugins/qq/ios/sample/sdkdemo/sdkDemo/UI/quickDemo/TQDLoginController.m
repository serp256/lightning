//
//  TQDLoginController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-18.
//
//

#import "TQDLoginController.h"
#import "QuickDemoViewController.h"
#import "iToast.h"

@interface TQDLoginController ()

@end

@implementation TQDLoginController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)accessTokenChanged:(NSString *)newValue
{
    if ([[QuickDemoViewController sharedInstance].tencentOAuth accessToken].length > 0) {
        self.root.title = @"登陆成功";
        for (QSection *section in self.root.sections) {
            for (QBooleanElement *element in section.elements) {
                element.enabled = NO;
            }
        }
        [self.root elementWithKey:@"loginButton"].hidden = YES;
        [self.root elementWithKey:@"logoutButton"].hidden = NO;
        [self.root elementWithKey:@"logoutButton"].enabled = YES;
    } else {
        self.root.title = @"登陆";
        for (QSection *section in self.root.sections) {
            for (QBooleanElement *element in section.elements) {
                element.enabled = YES;
            }
        }
        [self.root elementWithKey:@"loginButton"].hidden = NO;
        [self.root elementWithKey:@"loginButton"].enabled = YES;
        [self.root elementWithKey:@"logoutButton"].hidden = YES;
    }
    [self.root elementWithKey:@"DAUButton"].enabled = YES;
    [self.quickDialogTableView reloadData];
}

- (void)onLogin:(id)sender
{
    NSMutableArray *permissions = [[[NSMutableArray alloc] init] autorelease];
    QSection *section = [self.root sectionWithKey:@"permission_switchs_section"];
    for (QBooleanElement *element in section.elements) {
        if ([element isKindOfClass:[QBooleanElement class]]) {
            if (element.boolValue) {
                [permissions addObject:element.title];
            }
        }
    }
    [[QuickDemoViewController sharedInstance].tencentOAuth authorize:permissions inSafari:YES];
}

- (void)onLogout:(id)sender
{
    NSMutableArray *permissions = [[[NSMutableArray alloc] init] autorelease];
    QSection *section = [self.root sectionWithKey:@"permission_switchs_section"];
    for (QBooleanElement *element in section.elements) {
        if ([element isKindOfClass:[QBooleanElement class]]) {
            if (element.boolValue) {
                [permissions addObject:element.title];
            }
        }
    }
    [[QuickDemoViewController sharedInstance].tencentOAuth logout:nil];
}

- (void)onDAU:(id)sender
{
    NSMutableArray *permissions = [[[NSMutableArray alloc] init] autorelease];
    QSection *section = [self.root sectionWithKey:@"permission_switchs_section"];
    for (QBooleanElement *element in section.elements) {
        if ([element isKindOfClass:[QBooleanElement class]]) {
            if (element.boolValue) {
                [permissions addObject:element.title];
            }
        }
    }
    [[QuickDemoViewController sharedInstance].tencentOAuth authorize:permissions];
}

- (void)tencentDidLogin
{
    NSString *accessToken = [QuickDemoViewController sharedInstance].tencentOAuth.accessToken;
    if (accessToken.length > 0) {
        [[iToast makeText:[NSString stringWithFormat:@"登录成功\nOpenID:%@\nAccessToken: %@!\n", self.tencentOAuth.openId, self.tencentOAuth.accessToken]] show:iToastTypeInfo];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if (self.navigationController.topViewController == self) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        });
    } else {
        [[iToast makeText:@"登录失败\n没有获取到AccessToken!\n"] show:iToastTypeError];
    }
}

- (void)tencentDidNotLogin:(BOOL)cancelled
{
    if (cancelled) {
        [[iToast makeText:@"取消登录"] show:iToastTypeInfo];
    } else {
        [[iToast makeText:@"登录失败"] show:iToastTypeError];
    }
}

- (void)tencentDidNotNetWork
{
    [[iToast makeText:@"无网络连接，请设置网络"] show:iToastTypeWarning];
}

- (void)tencentDidLogout
{
    [[iToast makeText:@"成功退出登陆"] show:iToastTypeWarning];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        if (self.navigationController.topViewController == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    });
}

@end
