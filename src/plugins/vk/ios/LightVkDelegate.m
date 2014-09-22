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

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken {
	*authorized = 1;
	[newToken saveTokenToDefaults:@"lightning_nativevk_token"];
	RUN_CALLBACK(success, Val_unit);

}

- (void)vkSdkAcceptedUserToken:(VKAccessToken *)token {

}
- (void)vkSdkRenewedToken:(VKAccessToken *)newToken {
	[newToken saveTokenToDefaults:@"lightning_nativevk_token"];
}

- (void)dealloc {
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
}

@end
