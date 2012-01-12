#import "FBConnect.h"
#import "FacebookController.h"
#import "FacebookDialogDelegate.h"
#import "FacebookRequestDelegate.h"
#import "fbwrapper_ios.h"

static FacebookController * fbcontroller = nil;

/*
 * 
 */ 
void ml_facebook_init(value appid) {
  CAMLparam1(appid);
  
  if (fbcontroller == nil) {
    fbcontroller = [[FacebookController alloc] initWithAppId: [NSString stringWithCString:String_val(appid) encoding:NSASCIIStringEncoding]];
  }
  
  CAMLreturn0;
}

/*
 * 
 */ 
value ml_facebook_check_auth_token() {
  CAMLparam0();
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
      fbcontroller.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
      fbcontroller.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
  }  

  CAMLreturn(Val_bool([fbcontroller.facebook isSessionValid]));
}



value ml_facebook_get_auth_token() {
  CAMLparam0();
  
  if (fbcontroller != nil) {
    CAMLreturn(caml_copy_string([fbcontroller.facebook.accessToken UTF8String]));
  } else {
    CAMLreturn(caml_copy_string(""));
  }
  
}

/*
 * TODO: add permissions
 */
void ml_facebook_authorize(value permissions) {
  CAMLparam1(permissions);
  
  if (fbcontroller) {
    [fbcontroller.facebook authorize: nil];
  }
  
  CAMLreturn0;
}


/*
 * 
 */
void ml_facebook_request(value graph_path, value params, value request_id) {
  CAMLparam3(graph_path, params, request_id);
  
  NSMutableDictionary * paramsDict = [[NSMutableDictionary alloc] initWithCapacity: 3];
  NSString * gPath = [NSString stringWithCString:String_val(graph_path) encoding:NSASCIIStringEncoding];

  value el = params;
  value prm;
  
  while (Is_block(el)) {
    prm = Field(el,0);
    NSString * key = [NSString stringWithCString:String_val(Field(prm,0)) encoding:NSASCIIStringEncoding];
    NSString * val = [NSString stringWithCString:String_val(Field(prm,1)) encoding:NSASCIIStringEncoding];
    [paramsDict setValue:val forKey:key];
    el = Field(el,1);
  }
      
  FacebookRequestDelegate * fbrDelegate = [[FacebookRequestDelegate alloc] initWithRequestID: Int_val(request_id)];
  [fbcontroller.facebook requestWithGraphPath:gPath andParams:paramsDict andDelegate:fbrDelegate];
  CAMLreturn0;
}





/*
 *
 */
void ml_facebook_open_apprequest_dialog(value ml_message, value ml_recipients, value ml_filter, value ml_title, value ml_dialog_id) {
  CAMLparam5(ml_message, ml_recipients, ml_filter, ml_title, ml_dialog_id);

  NSMutableDictionary * paramsDict = [NSMutableDictionary dictionaryWithCapacity: 3];
  
  if (caml_string_length(ml_message) > 0) {
    [paramsDict setValue: [NSString stringWithCString:String_val(ml_message) encoding:NSASCIIStringEncoding] forKey: @"message"];
  }
  
  if (caml_string_length(ml_filter) > 0) {
    [paramsDict setValue: [NSString stringWithCString:String_val(ml_filter) encoding:NSASCIIStringEncoding] forKey: @"filter"];
  }
  
  if (caml_string_length(ml_title) > 0) {
    [paramsDict setValue: [NSString stringWithCString:String_val(ml_title) encoding:NSASCIIStringEncoding] forKey: @"title"];
  }  
  
  if (caml_string_length(ml_recipients) > 0) {
    [paramsDict setValue: [NSString stringWithCString:String_val(ml_recipients) encoding:NSASCIIStringEncoding] forKey: @"to"];
  }    

  FacebookDialogDelegate * fbdDelegate = [[FacebookDialogDelegate alloc] initWithDialogID: Int_val(ml_dialog_id)];
  [fbcontroller.facebook dialog:@"apprequests" andParams:paramsDict  andDelegate: fbdDelegate];
  CAMLreturn0;
} 
 



