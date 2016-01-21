//
//  TQDQuickDialogController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-18.
//
//

#import "TQDQuickDialogController.h"
#import "QuickDemoViewController.h"
#import "iToast.h"

@interface TQDQuickDialogController ()

@end

@implementation TQDQuickDialogController

+ (void)initialize
{
    [super initialize];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [iToastSettings getSharedSettings].duration = 2200;
        [iToastSettings getSharedSettings].gravity = 0;
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [iToastSettings getSharedSettings].postition = CGPointMake(window.frame.size.width / 2, window.frame.size.height * 3 / 4);
    });
}

+ (NSMutableDictionary *)registeredControllers
{
    static NSMutableDictionary *registeredControllers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredControllers = [[NSMutableDictionary alloc] init];
    });
    return registeredControllers;
}

- (id)initWithRoot:(QRootElement *)rootElement
{
    self = [super initWithRoot:rootElement];
    if (self) {
        [[TQDQuickDialogController registeredControllers] setObject:self forKey:rootElement.controllerName];
    }
    return self;
}

- (void)dealloc
{
    [[[QuickDemoViewController sharedInstance] tencentOAuth] removeObserver:self forKeyPath:@"accessToken"];
    [super dealloc];
}

+ (TQDQuickDialogController *)controllerForName:(NSString *)name
{
    return [TQDQuickDialogController registeredControllers][name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[[QuickDemoViewController sharedInstance] tencentOAuth] addObserver:self forKeyPath:@"accessToken" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial) context:NULL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"accessToken"]) {
        id newValue = change[NSKeyValueChangeNewKey];
        if ([newValue isKindOfClass:[NSNull class]]) {
            [self accessTokenChanged:nil];
        } else {
            [self accessTokenChanged:newValue];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (TencentOAuth *)tencentOAuth
{
    return [QuickDemoViewController sharedInstance].tencentOAuth;
}

- (void)accessTokenChanged:(NSString *)newValue
{
    if ([[QuickDemoViewController sharedInstance].tencentOAuth accessToken]) {
        for (QSection *section in self.root.sections) {
            for (QBooleanElement *element in section.elements) {
                element.enabled = YES;
            }
        }
    } else {
        for (QSection *section in self.root.sections) {
            for (QBooleanElement *element in section.elements) {
                element.enabled = NO;
            }
        }
    }
}

- (void)responseDidReceived:(APIResponse*)response forMessage:(NSString *)message
{
    NSString *title = (response.retCode == URLREQUEST_SUCCEED && response.detailRetCode == kOpenSDKErrorSuccess) ? @"发送成功" : @"发送失败";
    if (response.message == nil && response.jsonResponse && response.jsonResponse[@"msg"]) {
        response.message = response.jsonResponse[@"msg"];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:[NSString stringWithFormat:@"ret(%d): %@\ndetails(%d): %@", response.retCode, response.errorMsg, response.detailRetCode, response.message]
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
