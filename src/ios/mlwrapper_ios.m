
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


void process_touches(UIView *view, NSSet* touches, UIEvent *event,  mlstage *mlstage) {
	PRINT_DEBUG("process touched");
	caml_acquire_runtime_system();
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
	caml_release_runtime_system();
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


value ml_deviceIdentifier(value p) {
	CAMLparam0();
	NSString *ident = [[UIDevice currentDevice] uniqueIdentifier];
	CAMLreturn(caml_copy_string([ident cStringUsingEncoding:NSASCIIStringEncoding]));
}


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

value ml_kv_storage_create() {
  CAMLparam0();
  CAMLreturn((value)[NSUserDefaults standardUserDefaults]);
}

void ml_kv_storage_commit(value storage) {
  CAMLparam1(storage);
  [(NSUserDefaults *)storage synchronize];
  CAMLreturn0;
}


value ml_kv_storage_get_string(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  NSString * val = [(NSUserDefaults *)storage stringForKey: key];
  if (val == nil) {
    CAMLreturn(Val_int(0));
  }
  
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,caml_copy_string([val cStringUsingEncoding:NSASCIIStringEncoding]));
  
  CAMLreturn(tuple);
}


value ml_kv_storage_get_bool(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  
  if ([(NSUserDefaults *)storage objectForKey: key] == nil) {
    CAMLreturn(Val_int(0));
  }
  
  BOOL val = [(NSUserDefaults *)storage boolForKey: key];
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,Val_bool(val));
  
  CAMLreturn(tuple);
}


value ml_kv_storage_get_int(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);
  CAMLlocal1(tuple);

  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  
  if ([(NSUserDefaults *)storage objectForKey: key] == nil) {
    CAMLreturn(Val_int(0));
  }
  
  NSInteger val = [(NSUserDefaults *)storage integerForKey: key];
  tuple = caml_alloc_tuple(1);
  Store_field(tuple,0,Val_int(val));
  
  CAMLreturn(tuple);
}


void ml_kv_storage_put_string(value storage, value key_ml, value val_ml) {
  CAMLparam3(storage, key_ml, val_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  NSString * val = [NSString stringWithCString:String_val(val_ml) encoding:NSUTF8StringEncoding];
  [(NSUserDefaults *)storage setObject: val forKey: key];
  CAMLreturn0;
}


void ml_kv_storage_put_bool(value storage, value key_ml, value val_ml) {
  CAMLparam3(storage, key_ml, val_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [(NSUserDefaults *)storage setBool: Bool_val(val_ml) forKey: key];
  CAMLreturn0;
}


void ml_kv_storage_put_int(value storage, value key_ml, value val_ml) {
  CAMLparam3(storage, key_ml, val_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [(NSUserDefaults *)storage setInteger: Int_val(val_ml) forKey: key];
  CAMLreturn0;
}



void ml_kv_storage_remove(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  [(NSUserDefaults *)storage removeObjectForKey: key];  
  CAMLreturn0;
}


value ml_kv_storage_exists(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);
  NSString * key = [NSString stringWithCString:String_val(key_ml) encoding:NSUTF8StringEncoding];
  
  if ([(NSUserDefaults *)storage objectForKey: key] == nil) {
    CAMLreturn(Val_false);
  }
  
  CAMLreturn(Val_true);
}




/* PAYMENTS */

void ml_payment_init(value success_cb, value error_cb) {
  CAMLparam2(success_cb, error_cb);

  LightViewController * c = [LightViewController sharedInstance];

  c->payment_success_cb = success_cb;
  c->payment_error_cb   = error_cb;   

  caml_register_global_root(&(c->payment_success_cb));
  caml_register_global_root(&(c->payment_error_cb));
  
  [[SKPaymentQueue defaultQueue] addTransactionObserver: c];
  
  CAMLreturn0;
}


void ml_payment_purchase(value product_id) {
  CAMLparam1(product_id);
  
  if ([SKPaymentQueue canMakePayments]) {
    SKPayment *payment = [SKPayment paymentWithProductIdentifier: STR_CAML2OBJC(product_id)];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
  } else {
    [[[[UIAlertView alloc] initWithTitle:@"error" message:@"In App Purchases are currently disabled. Please adjust your settings to enable In App Purchases." delegate:nil cancelButtonTitle:@"close" otherButtonTitles:nil] autorelease] show];
  }      
  
  CAMLreturn0;
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


// 
void ml_request_remote_notifications(value rntype, value success_cb, value error_cb) {
  LightViewController * c = [LightViewController sharedInstance];

  if (Is_block(c->remote_notification_request_success_cb)) {
    caml_remove_global_root(&(c->remote_notification_request_success_cb));
  }
  
  if (Is_block(c->remote_notification_request_error_cb)) {
    caml_remove_global_root(&(c->remote_notification_request_error_cb));
  }
  
  c->remote_notification_request_success_cb = success_cb;
  c->remote_notification_request_error_cb   = error_cb;

  caml_register_global_root(&(c->remote_notification_request_success_cb));
  caml_register_global_root(&(c->remote_notification_request_error_cb));

  [[UIApplication sharedApplication] registerForRemoteNotificationTypes: Int_val(rntype)];

  return;  
}


void ml_uncatchedError(value message) {
	NSString *error = [NSString stringWithCString:String_val(message) encoding:NSUTF8StringEncoding];
	[[LightViewController sharedInstance] lightError:error];
}

