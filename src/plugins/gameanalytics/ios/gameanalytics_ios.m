#import "GameAnalytics.h" 
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
#import "common_ios.h"
#import "mlwrapper_ios.h"
#import "LightViewController.h"

NSArray* readArrayFromValue (value v) {

    if (v != Val_int(0)) {        
        NSMutableArray* nsarr = nil;
        value head = Field(v, 0);

        while (Is_block(head)) {
            NSString* nsstr= [NSString stringWithCString:(String_val(Field(head, 0))) encoding:NSASCIIStringEncoding];

                if (!nsarr) nsarr = [[NSMutableArray alloc] init];
                [nsarr addObject:nsstr];                

            head = Field(head, 1);
        }
				return nsarr;
    }
		return nil;
}

value ml_ga_init (value vkey, value vsecret, value vversion, value vdebug, value vcurrencies, value vitemtypes, value vdimensions) {
	CAMLparam5(vkey,vsecret,vversion, vdebug, vcurrencies);
	CAMLxparam2(vitemtypes, vdimensions);

  NSString* nsv = [NSString stringWithFormat:@"%@ %@", @"ios", [LightViewController version]];
	NSString* nsversion = Is_block(vversion) ? [NSString stringWithCString:String_val(Field(vversion, 0)) encoding:NSASCIIStringEncoding] : nsv;
	NSLog(@"version %@, %@", nsv, nsversion); 
	[GameAnalytics configureBuild:nsversion];
	
	NSArray* nscurrencies = readArrayFromValue (vcurrencies);
	if (nscurrencies) {
		[GameAnalytics configureAvailableResourceCurrencies:nscurrencies];
	}
	NSArray* nsitemtypes = readArrayFromValue (vitemtypes);
	if (nsitemtypes) {
		[GameAnalytics configureAvailableResourceItemTypes:nsitemtypes];
	}
	NSArray* nsdimensions = readArrayFromValue (vdimensions);
	if (nsdimensions) {
		[GameAnalytics configureAvailableResourceCurrencies:nsdimensions];
	}


	if (Bool_val(vdebug)) {
		NSLog(@"GA: debug log enabled");
		[GameAnalytics setEnabledInfoLog:YES];
		[GameAnalytics setEnabledVerboseLog:YES];
	}

	NSString* nskey = [NSString stringWithCString:String_val(vkey) encoding:NSUTF8StringEncoding];
	NSString* nssecret = [NSString stringWithCString:String_val(vsecret) encoding:NSUTF8StringEncoding];
	[GameAnalytics initializeWithGameKey:nskey  gameSecret:nssecret];

	CAMLreturn(Val_unit);
}

value ml_ga_init_byte (value* argv, int argn) {
	return ml_ga_init(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}


value ml_ga_business_event (value vcartType, value vitemType, value vitemId, value vcurrency, value vamount) {
	CAMLparam5(vcartType, vitemType, vitemId, vcurrency, vamount);
	PRINT_DEBUG("ml_ga_business_event");

	NSString* nscartType = [NSString stringWithCString:String_val(vcartType) encoding:NSUTF8StringEncoding];
	NSString* nsitemType = [NSString stringWithCString:String_val(vitemType) encoding:NSUTF8StringEncoding];
	NSString* nsitemId = [NSString stringWithCString:String_val(vitemId) encoding:NSUTF8StringEncoding];
	NSString* nscurrency = [NSString stringWithCString:String_val(vcurrency) encoding:NSUTF8StringEncoding];
	[GameAnalytics addBusinessEventWithCurrency:nscurrency amount:(Int_val(vamount)) itemType:nsitemType itemId:nsitemId cartType:nscartType autoFetchReceipt: YES];

	CAMLreturn(Val_unit);
}

value ml_ga_business_event_byte(value* argv, int argn) {
	PRINT_DEBUG("ml_ga_business_event_byte");
    return ml_ga_business_event (argv[0], argv[1], argv[2], argv[3], argv[4]);
}


value ml_ga_resource_event (value vflowType, value vcurrency, value vamount, value vitemType, value vitemId) {
	CAMLparam5(vflowType, vcurrency, vamount, vitemType, vitemId);
	PRINT_DEBUG("ml_ga_resource_event");

	NSString* nsitemType = [NSString stringWithCString:String_val(vitemType) encoding:NSUTF8StringEncoding];
	NSString* nsitemId = [NSString stringWithCString:String_val(vitemId) encoding:NSUTF8StringEncoding];
	NSString* nscurrency = [NSString stringWithCString:String_val(vcurrency) encoding:NSUTF8StringEncoding];

	NSNumber *nsamount = [NSNumber numberWithDouble:Double_val(vamount)];
	GAResourceFlowType flowType;
	if (vflowType == caml_hash_variant("sink")) {
		flowType = GAResourceFlowTypeSink;
	} else if (vflowType == caml_hash_variant("source")) {
		flowType = GAResourceFlowTypeSource;
	} else {
			caml_failwith("GameAnalytics: Invalid resourceEvent hash variant");
		}

	if ([nsamount floatValue] <= 0.) {
		caml_failwith("Invalid amount: cannot be 0 or negative");
	}
	[GameAnalytics addResourceEventWithFlowType:flowType currency:nscurrency amount:nsamount itemType:nsitemType itemId:nsitemId];


	CAMLreturn(Val_unit);
}


value ml_ga_progression_event (value vstatus, value vprogression1, value vprogression2, value vprogression3, value vscore) {
	CAMLparam5(vstatus, vprogression1, vprogression2, vprogression3, vscore);
	PRINT_DEBUG("ml_ga_progression_event");
	

  GAProgressionStatus status;

	if (vstatus== caml_hash_variant("start")) {
		status = GAProgressionStatusStart; 
	} else if (vstatus == caml_hash_variant("complete")) {
		status = GAProgressionStatusComplete;
	} else if (vstatus == caml_hash_variant("fail")) {
		status = GAProgressionStatusFail;
	} else {
			caml_failwith("GameAnalytics: Invalid progressionEvent hash variant");
		}

	NSString* nsprogression1 = [NSString stringWithCString:String_val(vprogression1) encoding:NSUTF8StringEncoding];
	NSString* nsprogression2 = Is_block(vprogression2) ? [NSString stringWithCString:String_val(Field(vprogression2,0)) encoding:NSUTF8StringEncoding] : nil; 
	NSString* nsprogression3 = Is_block(vprogression3) ? [NSString stringWithCString:String_val(Field(vprogression3,0)) encoding:NSUTF8StringEncoding] : nil; 
	if (Is_block(vscore)) {
		[GameAnalytics addProgressionEventWithProgressionStatus:status progression01:nsprogression1 progression02:nsprogression2 progression03:nsprogression3 score:(Int_val(Field(vscore,0)))];
	}
	else {
		[GameAnalytics addProgressionEventWithProgressionStatus:status progression01:nsprogression1 progression02:nsprogression2 progression03:nsprogression3];
	}

	CAMLreturn(Val_unit);
}



value ml_ga_design_event (value vevType, value vf) {
	CAMLparam2(vevType, vf);
	
	PRINT_DEBUG("ml_ga_design_event");

	NSString* nsevType = [NSString stringWithCString:String_val(vevType) encoding:NSUTF8StringEncoding];

	if (Is_block(vf)) {
		NSNumber *f= [NSNumber numberWithDouble:Double_val(Field(vf,0))];
		[GameAnalytics addDesignEventWithEventId:nsevType value:f];
	}
	else {
		[GameAnalytics addDesignEventWithEventId:nsevType];
	}

	CAMLreturn(Val_unit);
}


value ml_ga_error_event (value vevType, value vmessage) {
	CAMLparam2(vevType, vmessage);
	PRINT_DEBUG("ml_ga_error_event");

	GAErrorSeverity evType;

	if (vevType== caml_hash_variant("edebug")) {
		evType = GAErrorSeverityDebug;
	} else if (vevType == caml_hash_variant("info")) {
		evType = GAErrorSeverityInfo;
	} else if (vevType == caml_hash_variant("warning")) {
		evType = GAErrorSeverityWarning;
	} else if (vevType == caml_hash_variant("error")) {
		evType = GAErrorSeverityError;
	} else if (vevType == caml_hash_variant("critical")) {
		evType = GAErrorSeverityCritical;
	} else {
			caml_failwith("GameAnalytics: Invalid errorEvent hash variant");
		}

	NSString* nsmessage = Is_block(vmessage) ? [NSString stringWithCString:String_val(Field(vmessage,0)) encoding:NSUTF8StringEncoding] : nil ;
	[GameAnalytics addErrorEventWithSeverity:evType message:nsmessage ];

	CAMLreturn(Val_unit);
}
