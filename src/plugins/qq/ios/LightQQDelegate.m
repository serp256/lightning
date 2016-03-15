
#import "mlwrapper_ios.h"
#import "LightQQDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "LightViewController.h"

@implementation LightQQDelegate
- (id)initWithSuccess:(value)s andFail:(value)f {
	self = [super init];
	REG_CALLBACK(s, success);
	REG_OPT_CALLBACK(f, fail);
	return self;
}

- (void)tencentDidLogin
{
		NSLog(@"tencentDidLogin");
		RUN_CALLBACK(success, Val_unit);
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
}

- (void)tencentDidNotLogin:(BOOL)cancelled
{
		NSLog(@"tencentDidNotLogin");
		RUN_CALLBACK(fail, caml_copy_string ("tencentDidNotLogin"));
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
}

- (void)tencentDidNotNetWork
{
		NSLog(@"tencentDidNotNetWork");
		RUN_CALLBACK(fail, caml_copy_string ("tencentDidNotNetWork"));
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
}

@end
