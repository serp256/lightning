#import "caml/mlvalues.h"
#import "FyberSDK.h"
#import <objc/runtime.h>
#import "LightViewController.h"
#import <caml/memory.h>
#import "VideoDelegate.h"
#import "mlwrapper.h"
#import <UnityAds/UnityAds.h>

value ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken, value v_test) {
	CAMLparam4(v_appId, v_userId, v_securityToken, v_test);

	NSString* m_appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
	NSString* m_userId = Is_block(v_userId) ? [NSString stringWithCString:String_val(Field(v_userId, 0)) encoding:NSASCIIStringEncoding] : nil;
	NSString* m_securityToken = Is_block(v_securityToken) ? [NSString stringWithCString:String_val(Field(v_securityToken, 0)) encoding:NSASCIIStringEncoding] : nil;

	[NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;

	FYBSDKOptions *options = [FYBSDKOptions optionsWithAppId:m_appId
																										userId:m_userId
																						 securityToken:m_securityToken];

	if (Bool_val(v_test)) {
		NSLog (@"UnityAds TEST MODE");
		[[UnityAds sharedInstance] setTestMode:YES];
		[[UnityAds sharedInstance] setDebugMode:YES];
	}
	[FyberSDK startWithOptions:options];
  [FyberSDK setLoggingLevel:Bool_val(v_test) ? 10 : 0];

	CAMLreturn(Val_unit);
}

 
/*
void offerWallViewControllerIMP(id self, SEL _cmd, SPOfferWallViewController* controller, NSInteger status) {
}
*/


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
	/*
	static int protoAdded = 0;
	if (!protoAdded) {
		Class cls = [LightViewController class];
		SEL sel = @selector(offerWallViewController:isFinishedWithStatus:);

		class_addMethod(cls, sel, (IMP)offerWallViewControllerIMP, "v@:@l");
		class_addProtocol(cls, @protocol(SPOfferWallViewControllerDelegate));

		protoAdded = 1;
	}

	if (class_conformsToProtocol([LightViewController class], objc_getProtocol("SPOfferWallViewControllerDelegate"))) {
		[SponsorPaySDK showOfferWallWithParentViewController:[LightViewController sharedInstance]];
	}
	*/
	/*
	NSLog(@"ml_sponsorPay_showOffers");
	INIT_DELEGATE;
	SPOfferWallViewController *offerWallVC = [SponsorPaySDK offerWallViewController];
	offerWallVC.delegate = delegate;
	offerWallVC.shouldFinishOnRedirect = YES;
	[offerWallVC showOfferWallWithParentViewController:[LightViewController sharedInstance]];
	*/
}



value ml_request_video(value callback) {
	CAMLparam1(callback);
	NSLog(@"ml_request_video call!!");

	INIT_DELEGATE;
	INIT_CONTROLLER;

	[delegate setRequestCallback:callback];
	[rewardedVideoController requestVideo];
	/*
	NSLog(@"canRequestOffers %d", [engageClient canRequestOffers]);
	if ([engageClient canRequestOffers]) {
		[delegate setRequestCallback:callback];
		[engageClient requestOffers];
	} else {
		value *ptr = &callback;
		RUN_CALLBACK(ptr, Val_false);
	}

	*/
	CAMLreturn(Val_unit);
}

value ml_show_video(value callback) {
	CAMLparam1(callback);
	INIT_DELEGATE;
	INIT_CONTROLLER;

	[delegate setShowCallback:callback];
	[[FyberSDK rewardedVideoController] presentRewardedVideoFromViewController:[LightViewController sharedInstance]];
/*

	NSLog(@"canStartOffers %d", [engageClient canStartOffers]);

	
	if ([engageClient canStartOffers]) {
		[delegate setShowCallback:callback];
		[engageClient startWithParentViewController:[LightViewController sharedInstance]];
	} else {
		value *ptr = &callback;
		RUN_CALLBACK(ptr, Val_false);
	}
*/

	CAMLreturn(Val_unit);
}

