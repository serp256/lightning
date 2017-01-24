#import "caml/mlvalues.h"
#import "FyberSDK.h"
#import <objc/runtime.h>
#import "LightViewController.h"
#import <caml/memory.h>
#import "VideoDelegate.h"
#import "mlwrapper.h"
// #import <Fyber_UnityAds/UnityAds.h>

#import "mlwrapper_ios.h"

value ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken, value v_test) {
	CAMLparam4(v_appId, v_userId, v_securityToken, v_test);

	NSString* m_appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
	NSString* m_userId = Is_block(v_userId) ? [NSString stringWithCString:String_val(Field(v_userId, 0)) encoding:NSASCIIStringEncoding] : nil;
	NSString* m_securityToken = Is_block(v_securityToken) ? [NSString stringWithCString:String_val(Field(v_securityToken, 0)) encoding:NSASCIIStringEncoding] : nil;

	[NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;

	FYBSDKOptions *options = [FYBSDKOptions optionsWithAppId:m_appId
																										userId:m_userId
																						 securityToken:m_securityToken];

	[FyberSDK startWithOptions:options];
	int loggingLevel = Bool_val(v_test) ? 10 : 0;
	NSLog (@"Fyber logging level %d", loggingLevel);
  	[FyberSDK setLoggingLevel:loggingLevel];

 //  	 NSLog ("@UnityAds version %@", [UnityAds getVersion]);
	//  if (Bool_val(v_test)) {
	// 	NSLog (@"UnityAds TEST MODE");
	// 	// [UnityAds setTestMode:YES];
	// 	[UnityAds setDebugMode:YES];
	// }

	CAMLreturn(Val_unit);
}


FYBRewardedVideoController* rewardedVideoController;
VideoDelegate* delegate = nil;

#define INIT_DELEGATE if (!delegate) {			\
		delegate = [[VideoDelegate alloc] init];			\
	}

#define INIT_CONTROLLER if (!rewardedVideoController) {			\
		rewardedVideoController = [FyberSDK rewardedVideoController]; \
		rewardedVideoController.delegate = delegate; \
	}

void ml_sponsorPay_showOffers() {
}



value ml_request_video(value callback) {
	CAMLparam1(callback);
	NSLog(@"ml_request_video call!!");

	INIT_DELEGATE;
	INIT_CONTROLLER;

	[delegate setRequestCallback:callback];
	[rewardedVideoController requestVideo];

	CAMLreturn(Val_unit);
}

value ml_show_video(value callback) {
	CAMLparam1(callback);
	NSLog(@"ml_show_video call!!");
	INIT_DELEGATE;
	INIT_CONTROLLER;

	[delegate setShowCallback:callback];
	[[FyberSDK rewardedVideoController] presentRewardedVideoFromViewController:[LightViewController sharedInstance]];
	CAMLreturn(Val_unit);
}

