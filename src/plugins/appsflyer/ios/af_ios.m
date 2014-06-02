#import "ios/AppsFlyerTracker.h"
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import <caml/fail.h>

value ml_af_set_key(value appid, value devkey) {
	if (!Is_block(appid)) caml_failwith("appsflyer application id should be provided on ios");

	[AppsFlyerTracker sharedTracker].appsFlyerDevKey = [NSString stringWithUTF8String:String_val(devkey)];
	[AppsFlyerTracker sharedTracker].appleAppID = [NSString stringWithUTF8String:String_val(Field(appid, 0))];

	return Val_unit;
}

value ml_af_set_user_id(value uid) {
	[AppsFlyerTracker sharedTracker].customerUserID = [NSString stringWithUTF8String:String_val(uid)];
	return Val_unit;
}


value ml_af_get_uid(value p) {
	NSString *uid = [AppsFlyerTracker sharedTracker].customerUserID;
	if (uid)
		return caml_copy_string([uid UTF8String]);
	else caml_copy_string("");
}

value ml_af_set_currency_code(value code) {
	[AppsFlyerTracker sharedTracker].currencyCode = [NSString stringWithUTF8String:String_val(code)];
	return Val_unit;
}


value ml_af_send_tracking(value p) {
	[[AppsFlyerTracker sharedTracker] trackAppLaunch];
	return Val_unit;
}


value ml_af_send_tracking_with_event(value evkey,value evval) {
	NSString *nsev = [NSString stringWithCString:String_val(evkey) encoding:NSASCIIStringEncoding];
	NSString *nsval = [NSString stringWithCString:String_val(evval) encoding:NSASCIIStringEncoding];
	[[AppsFlyerTracker sharedTracker] trackEvent:nsev withValue:nsval];

	return Val_unit;
}
