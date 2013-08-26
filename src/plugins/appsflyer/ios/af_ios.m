


#import "ios/AppsFlyer.h"
#import <caml/mlvalues.h>
#import <caml/fail.h>

static NSString *appID = nil;




value ml_af_set_key(value key) {
	appID = [[NSString alloc] initWithCString:String_val(key) encoding:NSASCIIStringEncoding];
	return Val_unit;
}



value ml_af_set_user_id(value uid) {
	NSString *nsuid = [NSString stringWithCString:String_val(uid) encoding:NSASCIIStringEncoding];
	[AppsFlyer setAppUID:nsuid];
	return Val_unit;
}


value ml_af_get_uid(value p) {
	NSString *uid = [AppsFlyer getAppsFlyerUID];
	return caml_copy_string([uid UTF8String]);
}

value ml_af_set_currency_code(value code) {
	NSString *nscode = [NSString stringWithCString:String_val(code) encoding:NSASCIIStringEncoding];
	[AppsFlyer setCurrencyCode:nscode];
	return Val_unit;
}


value ml_af_send_tracking(value p) {
	if (!appID) caml_failwith("AppsFlyer not initialized");
	[AppsFlyer notifyAppID:appID];
	return Val_unit;
}


value ml_af_send_tracking_with_event(value evkey,value evval) {
	if (!appID) caml_failwith("AppsFlyer not initialized");
	NSLog(@"send_tracking_with_event");
	NSString *nsev = [NSString stringWithCString:String_val(evkey) encoding:NSASCIIStringEncoding];
	NSString *nsval = [NSString stringWithCString:String_val(evval) encoding:NSASCIIStringEncoding];
	[AppsFlyer notifyAppID:appID event:nsev eventValue:nsval];
	return Val_unit;
}
