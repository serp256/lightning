#import "LightAppDelegate.h"
#import "LightViewController.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
//#import <UIKit/UIDevice.h>
#import "common_ios.h"

#import "TencentOAuth.h"

#import "mlwrapper_ios.h"

@interface LightQQDelegate : NSObject <TencentSessionDelegate> { 
	value *success;
	value *fail;
}

- (id)init;

- (id)initWithSuccess:(value)s andFail:(value)f;

- (void)tencentDidLogin;
- (void)tencentDidNotLogin:(BOOL)cancelled;
- (void)tencentDidNotNetWork;
@end
