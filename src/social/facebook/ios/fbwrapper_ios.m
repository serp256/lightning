#import "LightAppDelegate.h"
#import "fbwrapper_ios.h"

#define FBSESSION_CHECK if (!fbSession) caml_failwith("no active facebook session")
#define FREE_CALLBACK(callback) if (callback) {     \
    caml_remove_generational_global_root(callback); \
    free(callback);                                 \
}                                                   \

#define REGISTER_CALLBACK(callback, pointer) if (callback != Val_int(0)) {  \
    pointer = (value*)malloc(sizeof(value));                                \
    *pointer = Field(callback, 0);                                          \
    caml_register_generational_global_root(pointer);                        \
} else {                                                                    \
    pointer = nil;                                                          \
}                                                                           \

@implementation LightFBDialogDelegate
    - (id)initWithSuccessCallback:(value*)successCallback andFailCallback:(value*)failCallback {
        self = [super init];

        _successCallback = successCallback;
        _failCallback = failCallback;

        return self;
    }

    - (void)dialogDidComplete:(FBDialog*)dialog {
        NSLog(@"dialogDidComplete");

        if (_successCallback) {            
            caml_callback(*_successCallback, usersIds);
        }

        [self freeCallbacks];
    }

    - (void)dialogCompleteWithUrl:(NSURL*)url {
        NSLog(@"dialogCompleteWithUrl %@", [url query]);
        
        NSArray* params = [[[url query] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
        NSArray* keyValuePair;
        NSEnumerator* enumer = [params objectEnumerator];
        id param;

        while (param = [enumer nextObject]) {
            keyValuePair = [(NSString*)param componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
            
        }
    }

    - (void)dialogDidNotCompleteWithUrl:(NSURL*)url {
        NSLog(@"dialogDidNotCompleteWithUrl");
        usersIds = Val_int(0);
    }

    - (void)dialogDidNotComplete:(FBDialog*)dialog {
        NSLog(@"dialogDidNotComplete");
    }

    - (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error {
        NSLog(@"dialog didFailWithError call");

        if (_failCallback) {
            caml_callback(*_failCallback, caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
        }

        [self freeCallbacks];
    }

    - (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url {
        NSLog(@"dialog shouldOpenURLInExternalBrowser call");
        return YES;
    }

    - (void)freeCallbacks {
        FREE_CALLBACK(_successCallback);
        FREE_CALLBACK(_failCallback);
    }
@end

static FBSession* fbSession = nil;
static Facebook* fb = nil;

void fbError(NSError* error) {
    caml_callback(*caml_named_value("fb_fail"), caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
}

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error) {
    NSLog(@"sessionStateChanged call");

    switch (state) {
        case FBSessionStateOpen:
            NSLog(@"FBSessionStateOpen");

            if (!error) {
                fbSession = session;
                caml_callback(*caml_named_value("fb_success"), Val_unit);
            } else {
                fbError(error);   
            }

            break;

        case FBSessionStateClosed:
            NSLog(@"FBSessionStateClosed");

            [[FBSession activeSession] closeAndClearTokenInformation];
            caml_callback(*caml_named_value("fb_sessionClosed"), Val_unit);
            break;

        case FBSessionStateClosedLoginFailed:
            NSLog(@"FBSessionStateClosedLoginFailed");

            [[FBSession activeSession] closeAndClearTokenInformation];
            fbError(error);
            break;

        default:
            NSLog(@"default");
            break;
    }    
}

value ml_fbInit(value appId) {
    [FBSession setDefaultAppID:[NSString stringWithCString:String_val(appId) encoding:NSASCIIStringEncoding]];
    return Val_unit;
}

void ml_fbConnect() {
    NSLog(@"ml_fbConnect");

    if (!fbSession) {
        [FBSession openActiveSessionWithReadPermissions:nil
            allowLoginUI:YES
            completionHandler:^(FBSession* session, FBSessionState state, NSError* error) {
                sessionStateChanged(session, state, error);
            }
        ];
    }
}

value ml_fbLoggedIn() {
    if (!fbSession) {
        if ([FBSession openActiveSessionWithAllowLoginUI:NO]) {
            fbSession = [FBSession activeSession];
        }        
    }

    value retval;

    if (fbSession) {
        retval = caml_alloc(1, 0);
        Store_field(retval, 0, Val_unit);
    } else {
        retval = Val_int(0);
    }

    return retval;
}

value ml_fbAccessToken(value connect) {
    FBSESSION_CHECK;
    return caml_copy_string([fbSession.accessToken cStringUsingEncoding:NSASCIIStringEncoding]);
}

void ml_fbApprequest(value connect, value title, value message, value filter, value successCallback, value failCallback) {
    FBSESSION_CHECK;

    if (!fb) {
        fb = [[Facebook alloc] initWithAppId:fbSession.appID andDelegate:nil];
    }

    fb.accessToken = fbSession.accessToken;
    fb.expirationDate = fbSession.expirationDate;

    NSString* _title = [NSString stringWithCString:String_val(title) encoding:NSASCIIStringEncoding];
    NSString* _message = [NSString stringWithCString:String_val(message) encoding:NSASCIIStringEncoding];
    NSString* _filter = [NSString stringWithCString:String_val(filter) encoding:NSASCIIStringEncoding];
    value* _successCallback;
    value* _failCallback;

    REGISTER_CALLBACK(successCallback, _successCallback);
    REGISTER_CALLBACK(failCallback, _failCallback);  

    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:_title, @"title", _message, @"message", _filter, @"filter", nil];
    [fb dialog:@"apprequests" andParams:params andDelegate:[[LightFBDialogDelegate alloc] initWithSuccessCallback:_successCallback andFailCallback:_failCallback]];
}

void ml_fbApprequest_byte(value * argv, int argn) {
}

/*#import "FBConnect.h"
#import "FacebookController.h"
#import "FacebookDialogDelegate.h"
#import "FacebookRequestDelegate.h"
#import "fbwrapper_ios.h"

static FacebookController * fbcontroller = nil;

void ml_facebook_init(value appid) {
  CAMLparam1(appid);
  
  if (fbcontroller == nil) {
    fbcontroller = [[FacebookController alloc] initWithAppId: [NSString stringWithCString:String_val(appid) encoding:NSASCIIStringEncoding]];
  }
  
  CAMLreturn0;
}

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

void ml_facebook_authorize(value permissions) {
  CAMLparam1(permissions);
  
  if (fbcontroller) {
    [fbcontroller.facebook authorize: nil];
  }
  
  CAMLreturn0;
}


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
}*/