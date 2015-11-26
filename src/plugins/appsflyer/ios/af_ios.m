#import "ios/AppsFlyerTracker.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
#import "common_ios.h"
#import "mlwrapper_ios.h"

value ml_af_set_key(value appid, value devkey) {
	if (!Is_block(appid)) caml_failwith("appsflyer application id should be provided on ios");
	//[AppsFlyerTracker sharedTracker].isDebug = true;
	[AppsFlyerTracker sharedTracker].appsFlyerDevKey = [NSString stringWithUTF8String:String_val(devkey)];
	[AppsFlyerTracker sharedTracker].appleAppID = [NSString stringWithUTF8String:String_val(Field(appid, 0))];

	return Val_unit;
}

value ml_af_set_user_id(value uid) {
	[AppsFlyerTracker sharedTracker].customerUserID = [NSString stringWithUTF8String:String_val(uid)];
	return Val_unit;
}


value ml_af_get_uid(value p) {
	NSString *uid = [[AppsFlyerTracker sharedTracker] getAppsFlyerUID];
	return caml_copy_string([uid UTF8String]);
}

value ml_af_set_currency_code(value code) {
	[AppsFlyerTracker sharedTracker].currencyCode = [NSString stringWithUTF8String:String_val(code)];
	return Val_unit;
}


value ml_af_send_tracking(value p) {
	[[AppsFlyerTracker sharedTracker] trackAppLaunch];
	return Val_unit;
}


/*
value ml_af_send_tracking_with_event(value evkey,value evval) {
	NSString *nsev = [NSString stringWithCString:String_val(evkey) encoding:NSASCIIStringEncoding];
	NSString *nsval = [NSString stringWithCString:String_val(evval) encoding:NSASCIIStringEncoding];
	[[AppsFlyerTracker sharedTracker] trackEvent:nsev withValue:nsval];

	return Val_unit;
}
*/

value ml_af_track_purchase(value vid, value vcurrency, value vrevenue) {
	PRINT_DEBUG("ml_track_purchase");
	CAMLparam3(vid,vcurrency,vrevenue);

	NSString *nsid = [NSString stringWithCString:String_val(vid) encoding:NSASCIIStringEncoding];
	NSString *nscurrency = [NSString stringWithCString:String_val(vcurrency) encoding:NSASCIIStringEncoding];
	NSNumber *nsrevenue = [NSNumber numberWithDouble:Double_val(vrevenue)];

	[[AppsFlyerTracker sharedTracker] trackEvent:AFEventPurchase withValues: @{AFEventParamContentId:nsid,
													 AFEventParamRevenue: nsrevenue,
													 AFEventParamCurrency:nscurrency}];

	CAMLreturn(Val_unit);
}

value ml_af_track_level (value vlevel) {
	PRINT_DEBUG("ml_track_level");
	CAMLparam1(vlevel);

	NSNumber *nslevel = [NSNumber numberWithInt:Int_val(vlevel)];
	[[AppsFlyerTracker sharedTracker] trackEvent: AFEventLevelAchieved withValues:@{ AFEventParamLevel: nslevel}];

	CAMLreturn(Val_unit);
}

value ml_af_track_tapjoy_event (value unit) {
	PRINT_DEBUG("ml_track_tapjoy_event");
	CAMLparam0();

	[[AppsFlyerTracker sharedTracker] trackEvent:@"tapjoy_action" withValue:@""];

	CAMLreturn(Val_unit);
}
