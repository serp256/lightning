#import "mlwrapper_ios.h"
#import "LightOkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "LightViewController.h"
#import "odnoklassniki_ios.h"

@implementation LightOkDelegate

- (id)init {
	self = [super init];
	return self;
}

- (void)authorizeWithSuccess:(value)s andFail:(value)f andAuthFl:(int*) fl {
	NSLog(@"okAuthorizeWithSuccess");
	authorized = fl;
	REG_CALLBACK(s, success);
	REG_OPT_CALLBACK(f, fail);
}

- (void)okShouldPresentAuthorizeController:(UIViewController *)viewController {
	NSLog(@"okShouldPresentAuthorizeController");
	[[LightViewController sharedInstance] presentViewController:viewController animated:YES completion:nil];
}

- (void)okWillDismissAuthorizeControllerByCancel:(BOOL)canceled {
	NSLog(@"okWillDismissAuthorizeControllerByCancel");
	if (canceled) {
		*authorized = 0;
		RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithString:@"Authorization cancelled by user"] UTF8String]));
	}
}

- (void)okDidLogin {
	NSLog(@"okDidLogin");
	*authorized = 1;
	get_current_user (fail,success);

	//RUN_CALLBACK(success, Val_unit);
}

- (void)okDidNotLogin:(BOOL)canceled {
	NSLog(@"okDidNotLogin");
	*authorized = 0;
	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithFormat:@"User cancels authorization: %i", canceled] UTF8String]));
}

- (void)okDidNotLoginWithError:(NSError *)error {
	NSLog(@"okDidNotLoginiWithError");
	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithFormat:@"%@", [error localizedDescription] ] UTF8String]));
}

- (void)okDidExtendToken:(NSString *)accessToken {
	NSLog(@"okDidExtendToken");
	[self okDidLogin];
}

- (void)okDidNotExtendToken:(NSError *)error {
	NSLog(@"okDidNotExtendToken");
	*authorized = 0;
	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithString:@"Did not extend token"] UTF8String]));
}

- (void)okDidLogout {
	NSLog(@"okDidLogout");
	*authorized = 0;
	//reauthorize (Val_unit);
}

- (void)dealloc {
	NSLog(@"ok delegate dealloc");
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
}
@end

