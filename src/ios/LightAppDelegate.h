#import <UIKit/UIKit.h>
#import "LightViewController.h"  
#import <FacebookSDK/FacebookSDK.h>

@interface LightAppDelegate : NSObject <UIApplicationDelegate,OrientationDelegate> {
    UIAlertView * inappPurchaseActivity;
    LightViewController * lightViewController;
    UIWindow * _window;
}

@property (nonatomic, retain) UIWindow *window;

@end
