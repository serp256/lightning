#import <UIKit/UIKit.h>
#import "LightViewController.h"  

@interface LightAppDelegate : NSObject <UIApplicationDelegate,OrientationDelegate> {
    UIAlertView * inappPurchaseActivity;
    LightViewController * lightViewController;
    UIWindow * _window;
}

@property (nonatomic, retain) UIWindow *window;

@end
