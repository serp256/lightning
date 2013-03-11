#import "LightAppDelegate.h"
#import "LightViewController.h"
#import "FBSBJSON.h"
#import "fbwrapper_ios.h"

#define FBSESSION_CHECK if (!fbSession) caml_failwith("no active facebook session") \

#define FREE_CALLBACK(callback) if (callback) {                                     \
    caml_remove_generational_global_root(callback);                                 \
    free(callback);                                                                 \
}                                                                                   \

#define REGISTER_CALLBACK(callback, pointer) if (callback != Val_int(0)) {  \
    pointer = (value*)malloc(sizeof(value));                                \
    *pointer = Field(callback, 0);                                          \
    caml_register_generational_global_root(pointer);                        \
} else {                                                                    \
    pointer = NULL;                                                         \
}                                                                           \

@implementation LightFBDialogDelegate
    - (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback {
        self = [super init];

				NSLog(@"initWithSuccessCallback");
        _successCallbackRequest = successCallback;
        _failCallbackRequest = failCallback;

        return self;
    }

    - (void)dialogDidComplete:(FBDialog*)dialog {
        NSLog(@"dialogDidComplete");

        if (_successCallbackRequest) {            
						NSLog(@"successCallback is call");
            caml_callback(*_successCallbackRequest, usersIds);
        } else {
						NSLog(@"successCallback not found");
				}

				NSLog(@"frrCallbacks");
        [self freeCallbacksRequests];
        [[LightViewController sharedInstance] becomeActive];
    }

    - (void)dialogCompleteWithUrl:(NSURL*)url {
        NSArray* params = [[[url query] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
        NSArray* keyValuePair;
        NSEnumerator* enumer = [params objectEnumerator];
        NSError* err = nil;
        NSRegularExpression* paramRegex = [NSRegularExpression regularExpressionWithPattern:@"to\\[\\d+\\]" options:0 error:&err];

        if (err) {
          caml_failwith([[err localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        id param;
        usersIds = Val_int(0);

        while (param = [enumer nextObject]) {
          keyValuePair = [(NSString*)param componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
          NSString* paramName = (NSString*)[keyValuePair objectAtIndex:0];          
          NSUInteger matchesNum = [paramRegex numberOfMatchesInString:paramName options:0 range:NSMakeRange(0, [paramName length])];

          if (matchesNum) {
            NSString* paramValue = (NSString*)[keyValuePair objectAtIndex:1];
            value lst = caml_alloc(2, 0);

            Store_field(lst, 0, caml_copy_string([paramValue cStringUsingEncoding:NSUTF8StringEncoding]));
            Store_field(lst, 1, usersIds);

            usersIds = lst;
          }
        }
    }

    - (void)dialogDidNotCompleteWithUrl:(NSURL*)url {
        NSLog(@"dialogDidNotCompleteWithUrl");
        usersIds = Val_int(0);
    }

    - (void)dialogDidNotComplete:(FBDialog*)dialog {
        NSLog(@"dialogDidNotComplete");
        [[LightViewController sharedInstance] becomeActive];
    }

    - (void)dialog:(FBDialog*)dialog didFailWithError:(NSError*)error {
        NSLog(@"dialog didFailWithError call");

        if (_failCallbackRequest) {
            caml_callback(*_failCallbackRequest, caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
        }

				NSLog(@"!!!!!!!!!!!!!frrCallbacks");
        [self freeCallbacksRequests];
        [[LightViewController sharedInstance] becomeActive];
    }

    - (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url {
        NSLog(@"dialog shouldOpenURLInExternalBrowser call");
        [[LightViewController sharedInstance] becomeActive];
        return YES;
    }

    - (void)freeCallbacksRequests {
				NSLog(@"freeCallback");
        FREE_CALLBACK(_successCallbackRequest);
        FREE_CALLBACK(_failCallbackRequest);

        _successCallbackRequest = nil;
        _failCallbackRequest = nil;
    }

    - (void)dealloc {
        NSLog(@"!!!dealloc");
        [super dealloc];
    }
@end

static FBSession* fbSession = nil;
static Facebook* fb = nil;

void fbError(NSError* error) {
    caml_callback(*caml_named_value("fb_fail"), caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
}

NSMutableArray* readPermissions = nil;
NSMutableArray* publishPermissions = nil;

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error);

/*void readPermissionsHandler(FBSession *session, NSError *error) {
    if (readPermissions) {
        [session reauthorizeWithReadPermissions:readPermissions completionHandler:^(FBSession *session, NSError *error) {
            [readPermissions dealloc];
            readPermissions = nil;            
        }]


    }
    sessionStateChanged(session, FBSessionStateOpen, error);
};

void publishPermissionsHandler(FBSession *session, NSError *error) {
    if (publishPermissions) {
        [publishPermissions dealloc];
        publishPermissions = nil;
    }
    sessionStateChanged(session, FBSessionStateOpen, error);
};*/

enum {
    NotRequested,
    ReadPermissionsRequsted,
    PublishPermissionsRequsted,
} extraPermsState = NotRequested;

void requestPublishPermissions() {
    if (publishPermissions && [publishPermissions count]) {
        NSLog(@"requesting additional publish permissions");
        extraPermsState = PublishPermissionsRequsted;
        [[FBSession activeSession] reauthorizeWithPublishPermissions:publishPermissions defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:nil];
    } else {
        NSLog(@"skip additional publish permissions");
        fbSession = [FBSession activeSession];
        extraPermsState = NotRequested;
        caml_callback(*caml_named_value("fb_success"), Val_unit);
    }
}

void requestReadPermissions() {
    if (readPermissions && [readPermissions count]) {        
        NSLog(@"requesting additional read permissions");
        extraPermsState = ReadPermissionsRequsted;
        [[FBSession activeSession] reauthorizeWithReadPermissions:readPermissions completionHandler:nil];
    } else {
        NSLog(@"skip additional read permissions");
        requestPublishPermissions();
    }
}

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error) {
    NSLog(@"sessionStateChanged call with error %@", error);

    //do nothing in this function when requesting extra permissions

    switch (state) {
        case FBSessionStateOpen:
            NSLog(@"FBSessionStateOpen %@", extraPermsState == NotRequested ? @"true" : @"false");

            if (extraPermsState == NotRequested) {
                requestReadPermissions();
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
    		if (!error) caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("Unknown Error"));
    		else fbError(error);
            break;

        case FBSessionStateCreated:
            NSLog(@"FBSessionStateCreated");
            break;

        case FBSessionStateCreatedTokenLoaded:
            NSLog(@"FBSessionStateCreatedTokenLoaded");
            break;

        case FBSessionStateCreatedOpening:
            NSLog(@"FBSessionStateCreatedOpening");
            break;

        case FBSessionStateOpenTokenExtended:
            NSLog(@"FBSessionStateOpenTokenExtended");

            switch (extraPermsState) {
                case ReadPermissionsRequsted:
                    NSLog(@"ReadPermissionsRequsted");

                    [readPermissions removeAllObjects];
                    [readPermissions release];
                    readPermissions = nil;
                    requestPublishPermissions();
                    break;

                case PublishPermissionsRequsted:
                    NSLog(@"PublishPermissionsRequsted");

                    [publishPermissions removeAllObjects];
                    [publishPermissions release];
                    publishPermissions = nil;
                    fbSession = session;
                    extraPermsState = NotRequested;
                    caml_callback(*caml_named_value("fb_success"), Val_unit);
                    break;
            }


            break;
    }    
}

void ml_fbInit(value appId) {
    [FBSession setDefaultAppID:[NSString stringWithCString:String_val(appId) encoding:NSASCIIStringEncoding]];
    NSNotificationCenter* notifCntr = [NSNotificationCenter defaultCenter];

    [notifCntr addObserverForName:APP_HANDLE_OPEN_URL_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification* notif) {
        NSLog(@"handling open url notification");
        if ([FBSession defaultAppID]) {
            NSLog(@"default app id");
            [[FBSession activeSession] handleOpenURL:[[notif userInfo] objectForKey:APP_HANDLE_OPEN_URL_NOTIFICATION_DATA]];
        }
    }];

    [notifCntr addObserverForName:APP_BECOME_ACTIVE_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification* notif) {
        NSLog(@"handling application become active");
        if ([FBSession defaultAppID]) {
            NSLog(@"default app id");
            [[FBSession activeSession] handleDidBecomeActive];
        }
    }];    
}

void ml_fbConnect(value permissions) {
    NSLog(@"ml_fbConnect");

    if (permissions != Val_int(0)) {        
        NSLog(@"parsing permission list");
        NSArray* publish_permissions = [NSArray arrayWithObjects:@"publish_actions", @"publish_actions",  @"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", nil];
        value perms = Field(permissions, 0);

        while (Is_block(perms)) {
            NSString* nsperm = [NSString stringWithCString:(String_val(Field(perms, 0))) encoding:NSASCIIStringEncoding];

            NSLog(@"permission %@", nsperm);

/*            NSError* err;
            NSRegularExpression* permRegex = [NSRegularExpression regularExpressionWithPattern:@"^(publish|manage).*" options:0 error:&err];
            NSUInteger matchesNum = [permRegex numberOfMatchesInString:nsperm options:0 range:NSMakeRange(0, [nsperm length])];*/
            
            // NSLog(@"matchesNum %lu", (unsigned long)matchesNum);

            if ([publish_permissions indexOfObject:nsperm] != NSNotFound) {
                if (!publishPermissions) publishPermissions = [[NSMutableArray alloc] init];
                [publishPermissions addObject:nsperm];                
            } else {
                if (!readPermissions) readPermissions = [[NSMutableArray alloc] init];
                [readPermissions addObject:nsperm];                
            }

            perms = Field(perms, 1);
        }

        // [publish_permissions release];
    }

    if (!fbSession) {
        [FBSession openActiveSessionWithReadPermissions:nil
            allowLoginUI:YES
            completionHandler:^(FBSession* session, FBSessionState state, NSError* error) {
                sessionStateChanged(session, state, error);
            }
        ];
    }
}

value ml_fbDisconnect(value connect) {
	NSLog(@"ml_fbDisconnect");
	if (fbSession) {
		fbSession.closeAndClearTokenInformation;
		fbSession.close;
		[FBSession setActiveSession:nil];
		fbSession = nil;
	}
//	if (fbSession) {
//		fvSession.closeAndClearTokenInformation;
//	}
}

value ml_fbLoggedIn() {
    if (!fbSession) {
        if ([FBSession openActiveSessionWithAllowLoginUI:NO] && [FBSession activeSession].isOpen) {
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

void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback) {
//		CAMLparam5(connect, title, message, recipient, data);
	//	CAMLxparam2(successCallback,failCallback);
    FBSESSION_CHECK;

    if (!fb) {
        fb = [[Facebook alloc] initWithAppId:fbSession.appID andDelegate:nil];
    }

    fb.accessToken = fbSession.accessToken;
    fb.expirationDate = fbSession.expirationDate;

    NSString* nstitle = [NSString stringWithCString:String_val(title) encoding:NSUTF8StringEncoding];
    NSString* nsmessage = [NSString stringWithCString:String_val(message) encoding:NSUTF8StringEncoding];
		NSLog(@"title=%@; message=%@",nstitle, nsmessage);

    value* _successCallbackRequest;
    value* _failCallbackRequest;

		NSLog(@"INIT SUCCESS CALLBACK IN APP REQUEST");
    REGISTER_CALLBACK(successCallback, _successCallbackRequest);
		if (_successCallbackRequest) {
			NSLog(@"success callback is init");
		} else {
			NSLog(@"success callback is NOT init");
		}
    REGISTER_CALLBACK(failCallback, _failCallbackRequest);

    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:nstitle, @"title", nsmessage, @"message", nil];

    if (Is_block(recipient)) {
        NSString* nsrecipient = [NSString stringWithCString:String_val(Field(recipient, 0)) encoding:NSASCIIStringEncoding];
        [params setObject:nsrecipient forKey:@"to"];
    }

    if (Is_block(data)) {
//				NSLog (@"data str: %@",String_val(Field(data, 0) ));
        NSString* nsdata = [NSString stringWithCString:String_val(Field(data, 0)) encoding:NSASCIIStringEncoding];
        [params setObject:nsdata forKey:@"data"];
    }

    static LightFBDialogDelegate* delegate;
//    if (!delegate) delegate = [[LightFBDialogDelegate alloc] initWithSuccessCallbackRequest:_successCallbackRequest andFailCallback:_failCallbackRequest];
    delegate = [[LightFBDialogDelegate alloc] initWithSuccessCallbackRequest:_successCallbackRequest andFailCallback:_failCallbackRequest];

    [[LightViewController sharedInstance] resignActive];
    [fb dialog:@"apprequests" andParams:params andDelegate:delegate];
		if (_successCallbackRequest) {
			NSLog(@"success callback is init");
		} else {
			NSLog(@"success callback is NOT init");
		}
}

void ml_fbApprequest_byte(value * argv, int argn) {}

/*void fbGraphrequest(NSString* nspath, NSDictionary* nsparams, value* successCallbackGraphApi, value* failCallbackGraphApi) {
    [FBRequestConnection startWithGraphPath:nspath parameters:nsparams HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"completionHandler");

        if (error) {
            NSArray *perms =[NSArray arrayWithObjects:@"publish_actions", nil];

            //fix it
            [[FBSession activeSession] reauthorizeWithPublishPermissions:perms defaultAudience:FBSessionDefaultAudienceEveryone
                                           completionHandler:^(FBSession *session, NSError *error) {
                                               fbGraphrequest(nspath, nsparams, successCallbackGraphApi, failCallbackGraphApi);
                                           }];
            return;
        } else {
            if (successCallbackGraphApi) {
                
                
                FBSBJSON* json = [[FBSBJSON alloc] init];
                NSError* err = nil;
                NSString* jsonResult = [json stringWithObject:result error:&err];

                NSLog(@"jsonResult %@", jsonResult);

                if (err) {
                    if (failCallbackGraphApi) {
                        caml_callback(*failCallbackGraphApi, caml_copy_string([[err localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
                    }
                } else {
                    caml_callback2(*caml_named_value("fb_graphrequestSuccess"), caml_copy_string([jsonResult cStringUsingEncoding:NSUTF8StringEncoding]), *successCallbackGraphApi);
                }

                [json release];
            }
        }

        NSLog(@"FREE SUCESSCALLBACK IN GRAPH API");
        FREE_CALLBACK(successCallbackGraphApi);
        FREE_CALLBACK(failCallbackGraphApi);        
    }];
}*/

void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback) {
    FBSESSION_CHECK;

    NSString* nspath = [NSString stringWithCString:String_val(path) encoding:NSASCIIStringEncoding];
    NSDictionary* nsparams = [NSMutableDictionary dictionary];

    NSLog(@"graph request %@", nspath);

    if (params != Val_int(0)) {
        value _params = Field(params, 0);
        value param;

        while (Is_block(_params)) {
            param = Field(_params, 0);
            NSString* key = [NSString stringWithCString:String_val(Field(param, 0)) encoding:NSASCIIStringEncoding];
            NSString* val = [NSString stringWithCString:String_val(Field(param, 1)) encoding:NSASCIIStringEncoding];
            [nsparams setValue:val forKey:key];
            _params = Field(_params, 1);
        }
    }

    value* _successCallbackGraphApi;
    value* _failCallbackGraphApi;
				
    REGISTER_CALLBACK(successCallback, _successCallbackGraphApi);
		if (_successCallbackGraphApi) {
			NSLog(@"success callback is init in graphApi");
		} else {
			NSLog(@"success callback is NOT init in graph");
		}
    REGISTER_CALLBACK(failCallback, _failCallbackGraphApi);

    // fbGraphrequest(nspath, nsparams, _successCallbackGraphApi, _failCallbackGraphApi);
    [FBRequestConnection startWithGraphPath:nspath parameters:nsparams HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"completionHandler");

        if (error) {
            if (_failCallbackGraphApi) {
                caml_callback(*_failCallbackGraphApi, caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
            }
        } else {
            if (_successCallbackGraphApi) {
                FBSBJSON* json = [[FBSBJSON alloc] init];
                NSError* err = nil;
                NSString* jsonResult = [json stringWithObject:result error:&err];

                NSLog(@"jsonResult %@", jsonResult);

                if (err) {
                    if (_failCallbackGraphApi) {
                        caml_callback(*_failCallbackGraphApi, caml_copy_string([[err localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
                    }
                } else {
                    caml_callback2(*caml_named_value("fb_graphrequestSuccess"), caml_copy_string([jsonResult cStringUsingEncoding:NSUTF8StringEncoding]), *_successCallbackGraphApi);
                }

                [json release];
            }
        }

	    NSLog(@"FREE SUCESSCALLBACK IN GRAPH API");
        FREE_CALLBACK(_successCallbackGraphApi);
        FREE_CALLBACK(_failCallbackGraphApi);        
    }];
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
