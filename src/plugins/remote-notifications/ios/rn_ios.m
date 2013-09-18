#import "LightViewController.h"
#import "mlwrapper_ios.h"
#import "caml/mlvalues.h"
#import <caml/alloc.h>


@interface RNDelegate: NSObject <RemoteNotificationsRegisterDelegate>
-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
@end;

@implementation RNDelegate

-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

	PRINT_DEBUG("ml_rn_success");
	value *ml_success = caml_named_value("remote_notifications_success");

  value token = caml_alloc_string([deviceToken length]);
  memcpy(String_val(token), (const char *)[deviceToken bytes], [deviceToken length]);  
	caml_callback(*ml_success,token);
}

-(void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	PRINT_DEBUG("ml_rn_error");
	NSString *errdesc = [error localizedDescription];                                                                                                                                                     
	value err = caml_copy_string([errdesc cStringUsingEncoding:NSUTF8StringEncoding]);
	value *ml_fail = caml_named_value("remote_notifications_error");
	caml_callback(*ml_fail,err);
}

@end;


value ml_rnInit(value rntype,value sender_id_unused) {
	[LightViewController sharedInstance].rnDelegate = [[[RNDelegate alloc] init] autorelease];
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:Int_val(rntype)];
  return Val_unit;  
}

