//
//  QuickDemoViewController.m
//  tencentOAuthDemo
//
//  Created by 易壬俊 on 13-6-18.
//
//

#import "QuickDemoViewController.h"
#import "TQDQuickDialogController.h"

@interface QuickDemoViewController () <TencentSessionDelegate>

@end

@implementation QuickDemoViewController

+ (QuickDemoViewController *)sharedInstance
{
    static QuickDemoViewController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithRoot:[QuickDemoViewController createRootElement]];
    });
    return instance;
}

+ (QRootElement *)createRootElement
{
    QRootElement *root = [[[QRootElement alloc] init] autorelease];
    root.title = @"QuickDemo";
    root.grouped = YES;
    [root addSection:^(){
    	QSection *section = [[[QSection alloc] init] autorelease];
        [section addElement:[[[QRootElement alloc] initWithJSONFile:@"Login"] autorelease]];
        return section;
    }()];
    [root addSection:^(){
    	QSection *section = [[[QSection alloc] init] autorelease];
        section.title = @"Legacy";
        [section addElement:[[[QRootElement alloc] initWithJSONFile:@"SendStory"] autorelease]];
        return section;
    }()];
    [root addSection:^(){
    	QSection *section = [[[QSection alloc] init] autorelease];
        section.title = @"SDK 1.9 Added";
        [section addElement:[[[QRootElement alloc] initWithJSONFile:@"AppInvitation"] autorelease]];
        [section addElement:[[[QRootElement alloc] initWithJSONFile:@"AppChallenge"] autorelease]];
        [section addElement:[[[QRootElement alloc] initWithJSONFile:@"AppGiftRequest"] autorelease]];
        return section;
    }()];
    return root;
}

- (QuickDemoViewController *)initWithRoot:(QRootElement *)rootElement
{
    self = [super initWithRoot:rootElement];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [_tencentOAuth release];
    _tencentOAuth = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:PreDefM_APPID andDelegate:self];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - TencentLoginDelegate

- (void)tencentDidLogin
{
    id controller = [TQDQuickDialogController controllerForName:@"TQDLoginController"];
    if ([controller respondsToSelector:_cmd]) {
        [controller tencentDidLogin];
    }
}

- (void)tencentDidNotLogin:(BOOL)cancelled
{
    id controller = [TQDQuickDialogController controllerForName:@"TQDLoginController"];
    if ([controller respondsToSelector:_cmd]) {
        [controller tencentDidNotLogin:cancelled];
    }
}

- (void)tencentDidNotNetWork
{
    id controller = [TQDQuickDialogController controllerForName:@"TQDLoginController"];
    if ([controller respondsToSelector:_cmd]) {
        [controller tencentDidNotNetWork];
    }
}

#pragma mark - TencentSessionDelegate

- (void)tencentDidLogout
{
    id controller = [TQDQuickDialogController controllerForName:@"TQDLoginController"];
    if ([controller respondsToSelector:_cmd]) {
        [controller tencentDidLogout];
    }
}

- (void)responseDidReceived:(APIResponse*)response forMessage:(NSString *)message
{
    id controller = [TQDQuickDialogController controllerForName:[NSString stringWithFormat:@"TQD%@Controller", message]];
    if ([controller respondsToSelector:_cmd]) {
        [controller performSelector:_cmd withObject:response withObject:message];
    }
}

@end
