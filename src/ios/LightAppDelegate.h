#import <UIKit/UIKit.h>
#import "LightViewController.h"  

#define APP_BECOME_ACTIVE_NOTIFICATION @"applicationBecomeActive"
#define APP_HANDLE_OPEN_URL_NOTIFICATION @"applicationHandleOpenUrl"
#define APP_HANDLE_OPEN_URL_NOTIFICATION_DATA @"applicationHandleOpenUrl"


@interface LightAppDelegate : NSObject <UIApplicationDelegate,OrientationDelegate> {
    UIAlertView * inappPurchaseActivity;
    LightViewController * lightViewController;
    UIWindow * _window;
}

@property (nonatomic, retain) UIWindow *window;

@end
