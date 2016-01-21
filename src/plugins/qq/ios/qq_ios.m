#import "LightAppDelegate.h"
#import "LightQQDelegate.h"
#import "LightViewController.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
//#import <UIKit/UIDevice.h>
#import "common_ios.h"

 #import <TencentOAuth.h>
//#import <MediaPlayer/MediaPlayer.h>
//#import <MobileCoreServices/MobileCoreServices.h>
//#import <CommonCrypto/CommonDigest.h>
//#import <TencentOpenAPI/TencentApiInterface.h>
//#import <TencentOpenAPI/TencentMessageObject.h>


#import "mlwrapper_ios.h"

static TencentOAuth *_tencentOAuth;
static NSString *appId;

value ml_qq_init (value vappid, value vuid, value vtoken, value vexpires) {
	CAMLparam4(vappid, vuid, vtoken, vexpires);

	PRINT_DEBUG ("ml_qq_init");


	appId = [NSString stringWithCString:String_val(vappid) encoding:NSUTF8StringEncoding];
	NSLog (@"appId %@", appId);

	CAMLreturn(Val_unit);
}

value ml_qq_authorize(value vfail, value vsuccess, value vforce) {
	CAMLparam3(vfail, vsuccess, vforce);

	PRINT_DEBUG ("ml_qq_authorize");

	NSArray* permissions = [NSArray arrayWithObjects:
									 kOPEN_PERMISSION_GET_USER_INFO,
									 kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
									 kOPEN_PERMISSION_ADD_SHARE,
									 nil];

	_tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"1105012296" andDelegate: [[LightQQDelegate alloc] initWithSuccess:vsuccess andFail:vfail]];

	if (vforce == Val_true) {
		PRINT_DEBUG ("qq: force logout");
		[_tencentOAuth logout: nil]; 
		}
	[_tencentOAuth authorize:permissions inSafari:NO];

	CAMLreturn(Val_unit);
}

value ml_qq_token(value unit) {
	if(_tencentOAuth) {
		if ([_tencentOAuth openId]) {
			return caml_copy_string([[_tencentOAuth openId] cStringUsingEncoding:NSASCIIStringEncoding]);
		}
		return (caml_copy_string(""));
	}
	return (caml_copy_string(""));
}

value ml_qq_uid(value unit) {
	if(_tencentOAuth) {
		if ([_tencentOAuth accessToken]) {
			return caml_copy_string([[_tencentOAuth accessToken] cStringUsingEncoding:NSASCIIStringEncoding]);
		}
		return (caml_copy_string(""));
	}
	return (caml_copy_string(""));
}

value ml_qq_logout (value unit) {
	if (_tencentOAuth) {
		[_tencentOAuth logout: nil]; 
  }
	return (Val_unit);
}

value ml_qq_friends(value vfail, value vsuccess) {
	CAMLparam2(vfail, vsuccess);

	value *success, *fail;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	CAMLreturn(Val_unit);
}



