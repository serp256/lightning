#import "mlwrapper_ios.h"
#import "LightVkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>

@implementation LightVkDelegate

- (id)initWithSuccess:(value)s andFail:(value)f andAuthFlag:(int*)fl
{
	REG_CALLBACK(s, success);
	REG_OPT_CALLBACK(f, fail);
	authorized = fl;

	return self;
}

// - (void)vkSdkDidAcceptUserToken:(VKAccessToken *)token
// {
// 	NSLog(@"!!!vkSdkDidAcceptUserToken");
// }
//
// - (void)vkSdkDidReceiveNewToken:(VKAccessToken *)newToken
// {
// 	NSLog(@"!!!vkSdkDidReceiveNewToken");
// 	*authorized = 1;
// 	RUN_CALLBACK(success, Val_unit);
// }
//
// - (void)vkSdkDidRenewToken:(VKAccessToken *)newToken
// {
// 	NSLog(@"!!!vkSdkDidRenewToken");
// }
//
// - (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
// {
// 	NSLog(@"!!!vkSdkNeedCaptchaEnter");
// }
//
// - (void)vkSdkShouldPresentViewController:(UIViewController *)controller
// {
// 	NSLog(@"!!!vkSdkShouldPresentViewController");
// }
//
// - (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
// {
// 	NSLog(@"!!!vkSdkTokenHasExpired");
// }
//
// - (void)vkSdkUserDeniedAccess:(VKError *)authorizationError
// {
// 	NSLog(@"!!!vkSdkUserDeniedAccess");
// 	*authorized = 0;
// 	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithFormat:@"%@: %@", authorizationError.errorMessage, authorizationError.errorReason ] UTF8String]));
// }
//
// - (void)dealloc
// {
// 	FREE_CALLBACK(success);
// 	FREE_CALLBACK(fail);
// }

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {

}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {

}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {
	*authorized = 0;
	RUN_CALLBACK(fail, caml_copy_string([[NSString stringWithFormat:@"%@: %@", authorizationError.errorMessage, authorizationError.errorReason ] UTF8String]));
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {

}

- (void)vkSdkDidReceiveNewToken:(VKAccessToken *)newToken {
	*authorized = 1;
	[newToken saveTokenToDefaults:@"lightning_nativevk_token"];
	RUN_CALLBACK(success, Val_unit);
}

- (void)vkSdkDidAcceptUserToken:(VKAccessToken *)token {

}

- (void)vkSdkDidRenewToken:(VKAccessToken *)newToken {
	[newToken saveTokenToDefaults:@"lightning_nativevk_token"];
}

- (void)dealloc {
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
}

@end
