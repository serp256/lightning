#import <UIKit/UIKit.h>
#import "LightViewController.h"  

#define APP_BECOME_ACTIVE_NOTIFICATION @"applicationBecomeActive"

#define APP_OPENURL @"APP_OPENURL"
#define APP_OPENURL_SOURCEAPP @"APP_OPENURL_SOURCEAPP"

#define APP_URL_DATA @"APP_URL_DATA"
#define APP_SOURCEAPP_DATA @"APP_SOURCEAPP_DATA"

@interface LightAppDelegate : NSObject <UIApplicationDelegate,OrientationDelegate> {
    UIAlertView * inappPurchaseActivity;
    LightViewController * lightViewController;
    UIWindow * _window;
}

@property (nonatomic, retain) UIWindow *window;

@end
