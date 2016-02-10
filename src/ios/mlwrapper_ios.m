
#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import <caml/threads.h>

#import "light_common.h"
#import "mlwrapper_ios.h"
#import "LightViewController.h"

char* bundle_path(char* c_path) {
  NSString *ns_path = [NSString stringWithCString:c_path encoding:NSASCIIStringEncoding];
  NSString *bundlePath = nil;
  NSArray * components = [ns_path pathComponents];
  //NSString * ext = [ns_path pathExtension];

  if ([components count] > 1) {
    bundlePath = [[NSBundle mainBundle] pathForResource: [components lastObject] ofType:nil inDirectory: [ns_path stringByDeletingLastPathComponent]];
  } else {
    bundlePath = [[NSBundle mainBundle] pathForResource:ns_path ofType:nil];
  }

  if (!bundlePath) return nil;

  const char* bpath = [bundlePath cStringUsingEncoding:NSASCIIStringEncoding];
  if (!bpath) return nil;

  char* retval = (char*)malloc(strlen(bpath) + 1);
  strcpy(retval, bpath);

  return retval;
}

void process_touches(UIView *view, NSSet* touches, UIEvent *event,  mlstage *mlstage) {
	PRINT_DEBUG("process touches %d", [touches count]);
	//caml_acquire_runtime_system();
	value mltouch = 1,mltouches = 1,globalX = 1,globalY = 1,time = 1, lst_el = 1;
  Begin_roots5(mltouch,time,globalX,globalY,mltouches);
  CGSize viewSize = view.bounds.size;
  float xConversion = mlstage->width / viewSize.width;
  float yConversion = mlstage->height / viewSize.height;
  mltouches = Val_int(0);
	time = caml_copy_double(0.);
  for (UITouch *uiTouch in touches) // [event touchesForView:view])
  {
    CGPoint location = [uiTouch locationInView:view];
		globalX = caml_copy_double(location.x * xConversion);
		globalY = caml_copy_double(location.y * yConversion);
    value mltouch = caml_alloc_tuple(8);
		Store_field(mltouch,0,caml_copy_int32((int)uiTouch));
		Store_field(mltouch,1,time);
		Store_field(mltouch,2,globalX);
		Store_field(mltouch,3,globalY);
		Store_field(mltouch,4,globalX);
		Store_field(mltouch,5,globalY);
		Store_field(mltouch,6,Val_int(uiTouch.tapCount));
		Store_field(mltouch,7,Val_int(uiTouch.phase));
    lst_el = caml_alloc_small(2,0);
    Field(lst_el,0) = mltouch;
    Field(lst_el,1) = mltouches;
    mltouches = lst_el;
  }
  mlstage_processTouches(mlstage,mltouches);
	if (mlstage->needCancelAllTouches) {
		mlstage->needCancelAllTouches = 0;
		NSLog(@"Call cancel all touches");
		mlstage_cancelAllTouches(mlstage);
	}
	End_roots();
	//caml_release_runtime_system();
  PRINT_DEBUG("process touches end");
}


void ml_showActivityIndicator(value mlpos) {
	CAMLparam1(mlpos);
	LightViewController *c = [LightViewController sharedInstance];
//	CGPoint pos = CGPointMake(Double_field(mlpos,0),Double_field(mlpos,1));
//	[c showActivityIndicator: pos];
    [c showActivityIndicator: nil];
	CAMLreturn0;
}

void ml_hideActivityIndicator(value p) {
	[[LightViewController sharedInstance] hideActivityIndicator];
}


/*
value ml_deviceIdentifier(value p) {
	CAMLparam0();
	NSString *ident = [[UIDevice currentDevice] uniqueIdentifier];
	CAMLreturn(caml_copy_string([ident cStringUsingEncoding:NSASCIIStringEncoding]));
}
*/


void ml_openURL(value mlurl) {
	CAMLparam1(mlurl);
	NSString *url = [NSString stringWithCString:String_val(mlurl) encoding:NSUTF8StringEncoding];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	CAMLreturn0;
}

void ml_show_alert(value otitle,value omessage) {
	PRINT_DEBUG("show alert");
	NSString *title = [NSString stringWithCString:String_val(otitle) encoding:NSUTF8StringEncoding];
	NSString *message = [NSString stringWithCString:String_val(omessage) encoding:NSUTF8StringEncoding];
	UIAlertView *alert = [[UIAlertView alloc] init];
	alert.title = title;
	alert.message = message;
	[alert show];
}


//////////// key-value storage based on NSUserDefaults

/*
value ml_kv_storage_create() {
  CAMLparam0();
  CAMLreturn((value)[NSUserDefaults standardUserDefaults]);
}
*/


#define USER_DEFAULTS [NSUserDefaults standardUserDefaults]

void ml_kv_storage_commit(value storage) {
  [USER_DEFAULTS synchronize];
}


value ml_kv_storage_get_string(value key_ml) {
  CAMLparam1(key_ml);
  CAMLlocal2(result,tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  NSData * val = [USER_DEFAULTS dataForKey:key];
  if (val == nil) {
    CAMLreturn(Val_int(0));
  }

	result = caml_alloc_string(val.length);
	[val getBytes:String_val(result) length:val.length];

  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,result);

  CAMLreturn(tuple);
}


value ml_kv_storage_get_bool(value key_ml) {
  CAMLparam1(key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];

	NSUserDefaults *d = USER_DEFAULTS;
  if ([d objectForKey: key] == nil) {
    CAMLreturn(Val_int(0));
  }

  BOOL val = [d boolForKey: key];
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,Val_bool(val));
   CAMLreturn(tuple);
}


value ml_kv_storage_get_int(value key_ml) {
  CAMLparam1(key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];

	NSUserDefaults *d = USER_DEFAULTS;
  if ([d objectForKey: key] == nil) {
    CAMLreturn(Val_int(0));
  }

  NSInteger val = [d integerForKey: key];
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,Val_int(val));

  CAMLreturn(tuple);
}

value ml_kv_storage_get_float(value key_ml) {
  CAMLparam1(key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];

  NSUserDefaults *d = USER_DEFAULTS;
  if ([d objectForKey: key] == nil) {
    CAMLreturn(Val_int(0));
  }

  double val = [d doubleForKey: key];
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,caml_copy_double(val));

  CAMLreturn(tuple);
}


void ml_kv_storage_put_string(value key_ml, value val_ml) {
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
	NSData * val = [NSData dataWithBytes:String_val(val_ml) length:caml_string_length(val_ml)];
  [USER_DEFAULTS setObject:val forKey: key];
}


void ml_kv_storage_put_bool(value key_ml, value val_ml) {
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [USER_DEFAULTS setBool: Bool_val(val_ml) forKey: key];
}


void ml_kv_storage_put_int(value key_ml, value val_ml) {
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [USER_DEFAULTS setInteger: Int_val(val_ml) forKey: key];
}

void ml_kv_storage_put_float(value key_ml, value val_ml) {
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [USER_DEFAULTS setFloat: Double_val(val_ml) forKey: key];
}



void ml_kv_storage_remove(value key_ml) {
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [USER_DEFAULTS removeObjectForKey: key];
}


value ml_kv_storage_exists(value key_ml) {
  CAMLparam1(key_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];

  if ([USER_DEFAULTS objectForKey: key] == nil) {
    CAMLreturn(Val_false);
  }

  CAMLreturn(Val_true);
}




/* PAYMENTS */

void ml_payment_init(value vskus, value success_cb, value error_cb) {
	CAMLparam3(vskus, success_cb, error_cb);
	LightViewController * c = [LightViewController sharedInstance];

	// if init twice?
	if (c->payment_success_cb == 0) {
		c->payment_success_cb = success_cb;
		caml_register_generational_global_root(&(c->payment_success_cb));
		c->payment_error_cb   = error_cb;
		caml_register_generational_global_root(&(c->payment_error_cb));
		[[SKPaymentQueue defaultQueue] addTransactionObserver: c];
	} else {
		caml_modify_generational_global_root(&(c->payment_success_cb),success_cb);
		caml_modify_generational_global_root(&(c->payment_error_cb),error_cb);
	};

	if (Is_block(vskus)) {
		NSCountedSet* skus = [[NSCountedSet alloc] initWithCapacity:10];
		value vsku = Field(vskus, 0);

		while (Is_block(vsku)) {
			char* csku = String_val(Field(vsku, 0));
			NSString* sku = [NSString stringWithUTF8String:csku];

			if (![skus member:sku]) {
				[skus addObject:sku];
			}

			vsku = Field(vsku, 1);
		}

		SKProductsRequest *preq = [[SKProductsRequest alloc] initWithProductIdentifiers:skus];
		preq.delegate = c;
		[preq start];
	}

	CAMLreturn0;
}

value ml_product_price(value vprod) {
	CAMLparam1(vprod);
	SKProduct* prod = (SKProduct*)vprod;
	NSLog(@"ml_product_price %@ %@", [ prod price], [prod priceLocale] );
	CAMLreturn(caml_copy_string([[NSString stringWithFormat:@"%@ %@", prod.price, [[prod priceLocale] objectForKey:NSLocaleCurrencyCode]] UTF8String]));
}

static value *create_details = NULL;

value ml_product_details(value vprod) {
	CAMLparam1(vprod);
	SKProduct* prod = (SKProduct*)vprod;
	NSLog(@"ml_product_price %@ %@", [ prod price], [prod priceLocale] );


	double amount = [[prod price] doubleValue];
	NSString *mcurrency = [[[prod priceLocale] objectForKey:NSLocaleCurrencyCode] UTF8String];
	value args[2] = { caml_copy_string(mcurrency),  caml_copy_double (amount)};

	if (!create_details) create_details= caml_named_value("create_product_details");

	CAMLreturn(caml_callbackN(*create_details, 2, args));

}

void purchase(value prod, int by_sku) {
	PRINT_DEBUG("purchase call %d", by_sku);

	if ([SKPaymentQueue canMakePayments]) {
    	SKPayment *payment = by_sku ? [SKPayment paymentWithProductIdentifier: STR_CAML2OBJC(prod)] : [SKPayment paymentWithProduct:(SKProduct*)prod];
    	[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else {
    	[[[[UIAlertView alloc] initWithTitle:@"error" message:@"In App Purchases are currently disabled. Please adjust your settings to enable In App Purchases." delegate:nil cancelButtonTitle:@"close" otherButtonTitles:nil] autorelease] show];
	}
}

value ml_payment_purchase_deprecated(value product_id) {
  CAMLparam1(product_id);
  purchase(product_id, 1);
  CAMLreturn(Val_unit);
}

value ml_payment_purchase(value vprod) {
	CAMLparam1(vprod);
	purchase(vprod, 0);
	CAMLreturn(Val_unit);
}

void ml_payment_commit_transaction(value t) {
  CAMLparam1(t);
  SKPaymentTransaction * transaction = (SKPaymentTransaction *)t;
  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
  [transaction release];
  CAMLreturn0;
}


// return transaction identifier
CAMLprim value ml_payment_get_transaction_id(value t) {
  CAMLparam1(t);
  SKPaymentTransaction * transaction = (SKPaymentTransaction *)t;
  CAMLreturn(caml_copy_string([transaction.transactionIdentifier cStringUsingEncoding:NSASCIIStringEncoding]));
}



// return transaction receipt for server side validation
CAMLprim value ml_payment_get_transaction_receipt(value t) {
  CAMLparam1(t);
  CAMLlocal1(receipt);
  SKPaymentTransaction * transaction = (SKPaymentTransaction *)t;

  receipt = caml_alloc_string([transaction.transactionReceipt length]);
  memmove(String_val(receipt), (const char *)[transaction.transactionReceipt bytes], [transaction.transactionReceipt length]);
  CAMLreturn(receipt);
}

value ml_payment_restore_completed_transactions(value p) {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	return Val_unit;
}


/*
void ml_uncatchedError(value message) {
	NSString *error = [NSString stringWithCString:String_val(message) encoding:NSUTF8StringEncoding];
	[[LightViewController sharedInstance] lightError:error];
}
*/



value ml_getDeviceType(value p) {
  value r = Val_int(0);
	//NSLog(@"getDeviceType: %d [ %d, %d]",[[UIDevice currentDevice] userInterfaceIdiom],UIUserInterfaceIdiomPhone,UIUserInterfaceIdiomPad);
  switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
    case UIUserInterfaceIdiomPhone: r = Val_int(0); break;
    case UIUserInterfaceIdiomPad: r = Val_int(1); break;
  };
  return r;
}


#include <malloc/malloc.h>

value ml_malinfo(value p) {
	struct mstats s = mstats();
	value res = caml_alloc_small(3,0);
	Field(res,0) = Val_int(s.bytes_total);
	Field(res,1) = Val_int(s.bytes_used);
	Field(res,2) = Val_int(s.bytes_free);
	return res;
}

char* get_locale() {
  NSString *identifier = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSArray *langLocaleArray = [identifier componentsSeparatedByString:@"-"];
	NSString *nsLocale = [langLocaleArray objectAtIndex:0];
  const char* locale = [nsLocale cStringUsingEncoding:NSASCIIStringEncoding];
  char* retval = (char*)malloc(strlen(locale) + 1);
  strcpy(retval, locale);

  return retval;
}

value ml_getLocale() {
  char* c_locale = get_locale();
	value v_locale = caml_copy_string(c_locale);
  free(c_locale);

	return v_locale;
}

value ml_getVersion() {
	NSString * vers = [LightViewController version];
	value s = caml_copy_string([vers UTF8String]);
	return s;
}

value ml_addExceptionInfo(value mlinfo) {
	NSString *info = [NSString stringWithCString:String_val(mlinfo) encoding:NSUTF8StringEncoding];
	[LightViewController addExceptionInfo:info];
	return Val_unit;
}

value ml_setSupportEmail(value mlemail) {
	NSString *email = [NSString stringWithCString:String_val(mlemail) encoding:NSASCIIStringEncoding];
	[LightViewController setSupportEmail:email];
	return Val_unit;
}

value ml_getStoragePath(value unit) {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
	NSString *directory = [paths objectAtIndex:0];
	NSLog(@"Documents directory: %@",directory);
	value result = caml_alloc_string(directory.length);
	[directory getCString:String_val(result) maxLength:(caml_string_length(result) + 1) encoding:NSUTF8StringEncoding];
	fprintf(stderr,"ocaml string: %s\n",String_val(result));
	return result;
}


#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import "OpenUDID.h"


static char *mac_address = NULL;
static const char default_mac_address[12]= "020000000000";

const char* getMacAddress() {
	int                 mib[6];
  size_t              len;
  char                *buf;
  unsigned char       *ptr;
  struct if_msghdr    *ifm;
  struct sockaddr_dl  *sdl;

  mib[0] = CTL_NET;
  mib[1] = AF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_LINK;
  mib[4] = NET_RT_IFLIST;


  if ((mib[5] = if_nametoindex("en0")) == 0)
  {
		return default_mac_address;
		/*
		PRINT_DEBUG("TRY TO GET IDENTIFIER FOR VENDOR");
		NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
		NSLog(@"IDENTIFIER FOR VENDOR: %@",uuid);
		if (uuid) return caml_copy_string([uuid UTF8String]);
		else {
			PRINT_DEBUG("TRY TO GEN UUID");
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			uuid = [userDefaults stringForKey:@"__UUID__"];
			if (uuid) return caml_copy_string([uuid UTF8String]);
			else {
				NSString *uuidString = nil;
				CFUUIDRef uuid = CFUUIDCreate(NULL);
				if (uuid) {
					CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
					[userDefaults setObject:(NSString*)uuidString forKey:@"__UUID__"];
					[userDefaults synchronize];
					NSLog(@"UUID now is: %@",[userDefaults stringForKey:@"__UUID__"]);
					CFRelease(uuid);
					CFIndex len = CFStringGetLength(uuidString) + 1;
					value res = caml_alloc_string(len);
					CFStringGetCString(uuidString,String_val(res),len,kCFStringEncodingUTF8);
					CFRelease(uuidString);
					return res;
				} else {
					caml_failwith("can't get UUID");
				}
			}
		}
		*/
  } else {

		if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
		{
			//caml_failwith("Error: sysctl, take 1");
			return default_mac_address;
		}

		if ((buf = malloc(len)) == NULL)
		{
			//caml_failwith("Could not allocate memory. error!");
			return default_mac_address;
		}

		if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
		{
			//caml_failwith("Error: sysctl, take 2");
			return default_mac_address;
		}

		ifm = (struct if_msghdr *)buf;
		sdl = (struct sockaddr_dl *)(ifm + 1);
		ptr = (unsigned char *)LLADDR(sdl);
		if (mac_address == NULL) mac_address = malloc(12);
		sprintf(mac_address,"%02X%02X%02X%02X%02X%02X",*ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
		return mac_address;
	}
}


value ml_getOldUDID(value p) {
	CAMLparam0();
	CAMLlocal1(res);
	const char* mac_address = getMacAddress();
	NSString *udid = [OpenUDID value];
	if (!udid) caml_failwith("can't get udid");
	// если он дефолтный, то плохо
	if (!strcmp(mac_address,default_mac_address)) {
		res = caml_copy_string([udid UTF8String]);
	} else {
		size_t len = 2 * 6 + 1 + [udid lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
		res = caml_alloc_string(len);
		sprintf(String_val(res),"%s_%s",mac_address,[udid UTF8String]);
	};
	CAMLreturn(res);
}


value ml_getUDID(value p) {
	NSString *nsres = nil;
	UIDevice *device = [UIDevice currentDevice];
	if ([device respondsToSelector:@selector(identifierForVendor)]) {
		NSUUID *udid = [UIDevice currentDevice].identifierForVendor;
		if (udid) nsres = [udid UUIDString];
		if ([nsres compare:@"00000000-0000-0000-0000-000000000000"] == NSOrderedSame) nsres = nil;
	};
	if (!nsres) nsres = [OpenUDID value];
	if (!nsres) caml_failwith("can't get UDID");
	NSLog(@"nsres: %@",nsres);
	value res = caml_copy_string([nsres cStringUsingEncoding:NSASCIIStringEncoding]);
	return res;
}



value ml_showNativeWait(value message) {
	return Val_unit;

}


value ml_hideNativeWait(value p) {
	return Val_unit;
}

value ml_str_to_lower(value vsrc) {
	CAMLparam1(vsrc);
	CAMLreturn(caml_copy_string([[[NSString stringWithUTF8String:String_val(vsrc)] lowercaseString] UTF8String]));
}

value ml_str_to_upper(value vsrc) {
	CAMLparam1(vsrc);
	CAMLreturn(caml_copy_string([[[NSString stringWithUTF8String:String_val(vsrc)] uppercaseString] UTF8String]));
}

value ml_alert(value mes) {
	CAMLparam1(mes);

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"pizda" message:@"pizda" delegate:nil cancelButtonTitle:@"pizda" otherButtonTitles:nil];
	[alert show];

	CAMLreturn(Val_unit);
}

value ml_silentUncaughtExceptionHandler(value vexn_json) {
    silentUncaughtException(String_val(vexn_json));
    return Val_unit;
}

value ml_uncaughtExceptionByMailSubjectAndBody() {
  CAMLparam0();
  CAMLlocal1(vres);


  NSBundle *bundle = [NSBundle mainBundle];
  NSString *subj = [bundle localizedStringForKey:@"exception_email_subject" value:@"Error report '%@'" table:nil];
  subj = [NSString stringWithFormat:subj, [bundle objectForInfoDictionaryKey: @"CFBundleDisplayName"]];
  UIDevice *dev = [UIDevice currentDevice];
  NSString *appVersion = [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
  NSString *body = [bundle localizedStringForKey:@"exception_email_body" value:@"" table:nil];
  body = [NSString stringWithFormat:body, dev.model, dev.systemVersion, appVersion];

  vres = caml_alloc_tuple(2);
  Store_field(vres, 0, caml_copy_string([subj UTF8String]));
  Store_field(vres, 1, caml_copy_string([body UTF8String]));

  CAMLreturn(vres);
}

value ml_setBackgroundDelayedCallback(value callback, value delay, value unit) {
    [[LightViewController sharedInstance] setBackgroundCallback:callback withDelay:Long_val(delay)];
    return Val_unit;
}

value ml_resetBackgroundDelayedCallback(value unit) {
    [[LightViewController sharedInstance] resetBackgroundDelayedCallback];
    return Val_unit;
}


value ml_enableAwake(value unit) {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    return Val_unit;
}

value ml_disableAwake(value unit) {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    return Val_unit;
}

value ml_systemVersion(value unit) {
	CAMLparam0();
	CAMLreturn(caml_copy_string([[[UIDevice currentDevice] systemVersion] UTF8String]));
}
value ml_model (value unit) {
	CAMLparam0();
	CAMLreturn(caml_copy_string([[[UIDevice currentDevice] model] UTF8String]));
}
value ml_deviceLocalTime (value unit) {
	CAMLparam0();

	NSDate* now = [NSDate date];
	int secondsFromGMT = [[NSTimeZone systemTimeZone] secondsFromGMT];
	double time = [[now dateByAddingTimeInterval:secondsFromGMT] timeIntervalSince1970];

	CAMLreturn(caml_copy_double(time));
}
