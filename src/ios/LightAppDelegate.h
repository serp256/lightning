#import <UIKit/UIKit.h>
#import "LightViewController.h"  

@interface LightAppDelegate : NSObject <UIApplicationDelegate> {
    UIAlertView * inappPurchaseActivity;
    LightViewController * lightViewController;
    UIWindow * _window;
}

@property (nonatomic, retain) UIWindow *window;

@end
