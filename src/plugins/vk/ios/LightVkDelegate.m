#import "mlwrapper_ios.h"
#import "LightVkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>

@implementation LightVkDelegate

- (id)initWithSuccess:(value)s andFail:(value)f
{
	REG_CALLBACK(s, success);
	REG_OPT_CALLBACK(f, fail);

	return self;
}

- (void)vkSdkDidAcceptUserToken:(VKAccessToken *)token
{
	NSLog(@"!!!vkSdkDidAcceptUserToken");
}

- (void)vkSdkDidReceiveNewToken:(VKAccessToken *)newToken
{
	NSLog(@"!!!vkSdkDidReceiveNewToken");
	RUN_CALLBACK(success, Val_unit);
}

- (void)vkSdkDidRenewToken:(VKAccessToken *)newToken
{
	NSLog(@"!!!vkSdkDidRenewToken");
}

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
	NSLog(@"!!!vkSdkNeedCaptchaEnter");
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
	NSLog(@"!!!vkSdkShouldPresentViewController");
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{
	NSLog(@"!!!vkSdkTokenHasExpired");
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError
{
	NSLog(@"!!!vkSdkUserDeniedAccess");
	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithFormat:@"%@: %@", authorizationError.errorMessage, authorizationError.errorReason ] UTF8String]));
}

- (void)dealloc
{
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
}

@end