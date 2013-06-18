#import "LightAppDelegate.h"
#import "LightViewController.h"
#import "FacebookSDK/FacebookSDK.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>

@interface LightFBDialogDelegate : NSObject <FBWebDialogsDelegate>
{
	value* _successCallbackRequest;
	value* _failCallbackRequest;
}

- (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback;
@end

/*
void ml_fbInit(value appid);

void ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken(value connect);
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback);
*/

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

/*
@implementation LightFBDialogDelegate
    - (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback {
        self = [super init];

				//NSLog(@"initWithSuccessCallback");
        _successCallbackRequest = successCallback;
        _failCallbackRequest = failCallback;

        return self;
    }


		- (void)webDialogsWillPresentDialog:(NSString *)dialog parameters:(NSMutableDictionary *)parameters session:(FBSession *)session {
			[[LightViewController sharedInstance] resignActive];
		}


		- (void)webDialogsWillDismissDialog:(NSString *)dialog parameters:(NSDictionary *)parameters session:(FBSession *)session 
																 result:(FBWebDialogResult *)result url:(NSURL **)url error:(NSError **)error 
		{
				switch (*result) {
					case FBWebDialogResultDialogCompleted:
						NSLog(@"Dismiss FBWebDialogResultDialogCompleted");
						if (_successCallbackRequest) {
							NSArray* params = [[[*url query] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
							NSArray* keyValuePair;
							NSEnumerator* enumer = [params objectEnumerator];
							NSRegularExpression* paramRegex = [NSRegularExpression regularExpressionWithPattern:@"to\\[\\d+\\]" options:0 error:nil];

							value lst = 1;
							value usersIds = Val_int(0);
							Begin_roots2(usersIds,lst);
							id param;

							while (param = [enumer nextObject]) {
								keyValuePair = [(NSString*)param componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
								NSString* paramName = (NSString*)[keyValuePair objectAtIndex:0];          
								NSUInteger matchesNum = [paramRegex numberOfMatchesInString:paramName options:0 range:NSMakeRange(0, [paramName length])];

								if (matchesNum) {
									NSString* paramValue = (NSString*)[keyValuePair objectAtIndex:1];
									lst = caml_alloc(2, 0);

									Store_field(lst, 0, caml_copy_string([paramValue cStringUsingEncoding:NSUTF8StringEncoding]));
									Store_field(lst, 1, usersIds);

									usersIds = lst;
								}
							}
							caml_callback(*_successCallbackRequest,usersIds);
							End_roots();
						};
						break;
					case FBWebDialogResultDialogNotCompleted:
						NSLog(@"Dismiss FBWebDialogResultDialogNotCompleted");
						if (_failCallbackRequest) {
							value mlError;
							if (*error) mlError = caml_copy_string([[*error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
							else mlError = caml_copy_string("Dialog Not Completed");
							caml_callback(*_failCallbackRequest, mlError);
						};
						break;
				};
				FREE_CALLBACK(_successCallbackRequest);
				FREE_CALLBACK(_failCallbackRequest);
				_successCallbackRequest = nil;
				_failCallbackRequest = nil;
				[self release];
				[[LightViewController sharedInstance] becomeActive];
		 }

@end
*/

static FBSession* fbSession = nil;

void fbError(NSError* error) {
    caml_callback(*caml_named_value("fb_fail"), caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
}

NSMutableArray* readPermissions = nil;
NSMutableArray* publishPermissions = nil;

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error);

enum {
    NotRequested,
    ReadPermissionsRequsted,
    PublishPermissionsRequsted,
} extraPermsState = NotRequested;

static inline void requestPublishPermissions() {
    if (publishPermissions && [publishPermissions count]) {
        //NSLog(@"requesting additional publish permissions");
        extraPermsState = PublishPermissionsRequsted;
        [[FBSession activeSession] requestNewPublishPermissions:publishPermissions defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:nil];
    } else {
        //NSLog(@"skip additional publish permissions");
        fbSession = [FBSession activeSession];
        extraPermsState = NotRequested;
        caml_callback(*caml_named_value("fb_success"), Val_unit);
    }
}

static inline void requestReadPermissions() {
    if (readPermissions && [readPermissions count]) {        
        //NSLog(@"requesting additional read permissions");
        extraPermsState = ReadPermissionsRequsted;
        [[FBSession activeSession] requestNewReadPermissions:readPermissions completionHandler:nil];
    } else {
        //NSLog(@"skip additional read permissions");
        requestPublishPermissions();
    }
}

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error) {
    //NSLog(@"sessionStateChanged call with error %@", error);

    //do nothing in this function when requesting extra permissions

    switch (state) {
        case FBSessionStateOpen:
            //NSLog(@"FBSessionStateOpen %@", extraPermsState == NotRequested ? @"true" : @"false");

            if (extraPermsState == NotRequested) {
                requestReadPermissions();
            }

            break;

        case FBSessionStateClosed:
            //NSLog(@"FBSessionStateClosed");

            [[FBSession activeSession] closeAndClearTokenInformation];
            caml_callback(*caml_named_value("fb_sessionClosed"), Val_unit);
            break;

        case FBSessionStateClosedLoginFailed:
            //NSLog(@"FBSessionStateClosedLoginFailed");

            [[FBSession activeSession] closeAndClearTokenInformation];
						if (!error) caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("Unknown Error"));
						else fbError(error);
            break;

        case FBSessionStateCreated:
            //NSLog(@"FBSessionStateCreated");
            break;

        case FBSessionStateCreatedTokenLoaded:
            //NSLog(@"FBSessionStateCreatedTokenLoaded");
            break;

        case FBSessionStateCreatedOpening:
            //NSLog(@"FBSessionStateCreatedOpening");
            break;

        case FBSessionStateOpenTokenExtended:
            //NSLog(@"FBSessionStateOpenTokenExtended");

            switch (extraPermsState) {
                case ReadPermissionsRequsted:
                    //NSLog(@"ReadPermissionsRequsted");

                    [readPermissions removeAllObjects];
                    [readPermissions release];
                    readPermissions = nil;
                    requestPublishPermissions();
                    break;

                case PublishPermissionsRequsted:
                    //NSLog(@"PublishPermissionsRequsted");

                    [publishPermissions removeAllObjects];
                    [publishPermissions release];
                    publishPermissions = nil;
                    fbSession = session;
                    [FBSession setActiveSession:session];
                    extraPermsState = NotRequested;
                    caml_callback(*caml_named_value("fb_success"), Val_unit);
                    break;
								case NotRequested: break;
            }


            break;
    }    
}

void ml_fbInit(value appId) {
    //[FBSettings setLoggingBehavior:[NSSet setWithObjects:FBLoggingBehaviorFBRequests, FBLoggingBehaviorFBURLConnections, FBLoggingBehaviorAccessTokens, FBLoggingBehaviorSessionStateTransitions, FBLoggingBehaviorDeveloperErrors, nil]];

    [FBSettings setDefaultAppID:[NSString stringWithCString:String_val(appId) encoding:NSASCIIStringEncoding]];
    NSNotificationCenter* notifCntr = [NSNotificationCenter defaultCenter];

    [notifCntr addObserverForName:APP_HANDLE_OPEN_URL_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification* notif) {
        //NSLog(@"handling open url notification");
        if ([FBSettings defaultAppID]) {
            [[FBSession activeSession] handleOpenURL:[[notif userInfo] objectForKey:APP_HANDLE_OPEN_URL_NOTIFICATION_DATA]];
        }
    }];

    [notifCntr addObserverForName:APP_BECOME_ACTIVE_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification* notif) {
        //NSLog(@"handling application become active");
        if ([FBSettings defaultAppID]) {
            [[FBSession activeSession] handleDidBecomeActive];
        }
    }];    
}

void ml_fbConnect(value permissions) {
    //NSLog(@"ml_fbConnect");

    if (permissions != Val_int(0)) {        
        //NSLog(@"parsing permission list");
        NSArray* publish_permissions = [NSArray arrayWithObjects:@"publish_actions", @"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", nil];
        value perms = Field(permissions, 0);

        while (Is_block(perms)) {
            NSString* nsperm = [NSString stringWithCString:(String_val(Field(perms, 0))) encoding:NSASCIIStringEncoding];

            //NSLog(@"permission %@", nsperm);

            if ([publish_permissions indexOfObject:nsperm] != NSNotFound) {
                if (!publishPermissions) publishPermissions = [[NSMutableArray alloc] init];
                [publishPermissions addObject:nsperm];                
            } else {
                if (!readPermissions) readPermissions = [[NSMutableArray alloc] init];
                [readPermissions addObject:nsperm];                
            }

            perms = Field(perms, 1);
        }
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

void ml_fbDisconnect(value connect) {
	//NSLog(@"ml_fbDisconnect");
	if (fbSession) {
		[fbSession closeAndClearTokenInformation];
		//[fbSession close];
		[FBSession setActiveSession:nil];
		fbSession = nil;
	}
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
    return caml_copy_string([fbSession.accessTokenData.accessToken cStringUsingEncoding:NSASCIIStringEncoding]);
}

void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback) {
//		CAMLparam5(connect, title, message, recipient, data);
	//	CAMLxparam2(successCallback,failCallback);
    FBSESSION_CHECK;

    NSString* nstitle = [NSString stringWithCString:String_val(title) encoding:NSUTF8StringEncoding];
    NSString* nsmessage = [NSString stringWithCString:String_val(message) encoding:NSUTF8StringEncoding];
		//NSLog(@"title=%@; message=%@",nstitle, nsmessage);

    value* _successCallbackRequest;
    value* _failCallbackRequest;

    REGISTER_CALLBACK(successCallback, _successCallbackRequest);
    REGISTER_CALLBACK(failCallback, _failCallbackRequest);

    //NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:nstitle, @"title", nsmessage, @"message", nil];
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];

    if (Is_block(recipient)) {
        NSString* nsrecipient = [NSString stringWithCString:String_val(Field(recipient, 0)) encoding:NSUTF8StringEncoding];
        [params setObject:nsrecipient forKey:@"to"];
    }

    if (Is_block(data)) {
//				NSLog (@"data str: %@",String_val(Field(data, 0) ));
        NSString* nsdata = [NSString stringWithCString:String_val(Field(data, 0)) encoding:NSUTF8StringEncoding];
        [params setObject:nsdata forKey:@"data"];
    }

    //LightFBDialogDelegate* delegate = [[LightFBDialogDelegate alloc] initWithSuccessCallbackRequest:_successCallbackRequest andFailCallback:_failCallbackRequest];
		//[FBWebDialogs presentDialogModallyWithSession:nil dialog:@"apprequests" parameters:params handler:nil delegate:delegate];
		[[LightViewController sharedInstance] resignActive];
		FBWebDialogHandler handler = ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
				switch (result) {
					case FBWebDialogResultDialogCompleted:
						//NSLog(@"Dismiss FBWebDialogResultDialogCompleted");
						if (_successCallbackRequest) {
							NSArray* params = [[[resultURL query] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
							NSArray* keyValuePair;
							NSEnumerator* enumer = [params objectEnumerator];
							NSRegularExpression* paramRegex = [NSRegularExpression regularExpressionWithPattern:@"to\\[\\d+\\]" options:0 error:nil];

							value lst = 1;
							value usersIds = Val_int(0);
							Begin_roots2(usersIds,lst);
							id param;

							while (param = [enumer nextObject]) {
								keyValuePair = [(NSString*)param componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
								NSString* paramName = (NSString*)[keyValuePair objectAtIndex:0];          
								NSUInteger matchesNum = [paramRegex numberOfMatchesInString:paramName options:0 range:NSMakeRange(0, [paramName length])];

								if (matchesNum) {
									NSString* paramValue = (NSString*)[keyValuePair objectAtIndex:1];
									lst = caml_alloc(2, 0);

									Store_field(lst, 0, caml_copy_string([paramValue cStringUsingEncoding:NSUTF8StringEncoding]));
									Store_field(lst, 1, usersIds);

									usersIds = lst;
								}
							}
							caml_callback(*_successCallbackRequest,usersIds);
							End_roots();
						};
						break;
					case FBWebDialogResultDialogNotCompleted:
						//NSLog(@"Dismiss FBWebDialogResultDialogNotCompleted");
						if (_failCallbackRequest) {
							value mlError;
							if (error) mlError = caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
							else mlError = caml_copy_string("Dialog Not Completed");
							caml_callback(*_failCallbackRequest, mlError);
						};
						break;
				};
				FREE_CALLBACK(_successCallbackRequest);
				FREE_CALLBACK(_failCallbackRequest);
				[[LightViewController sharedInstance] becomeActive];
		};
		static FBFrictionlessRecipientCache *cache = nil;
		if (!cache) cache = [[FBFrictionlessRecipientCache alloc] init];
		[FBWebDialogs presentRequestsDialogModallyWithSession:nil message:nsmessage title:nstitle parameters:params handler:handler friendCache:cache];
		//[delegate release];
		//if (!delegate) delegate = [[LightFBDialogDelegate alloc] initWithSuccessCallbackRequest:_successCallbackRequest andFailCallback:_failCallbackRequest];
    //delegate = [[LightFBDialogDelegate alloc] initWithSuccessCallbackRequest:_successCallbackRequest andFailCallback:_failCallbackRequest];
    //[[LightViewController sharedInstance] resignActive];
    //[fb dialog:@"apprequests" andParams:params andDelegate:delegate];
		/*if (_successCallbackRequest) {
			NSLog(@"success callback is init");
		} else {
			NSLog(@"success callback is NOT init");
		}*/
}

void ml_fbApprequest_byte(value * argv, int argn) {}

void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback) {
    FBSESSION_CHECK;

    NSString* nspath = [NSString stringWithCString:String_val(path) encoding:NSASCIIStringEncoding];
    NSDictionary* nsparams = [NSMutableDictionary dictionary];
    NSString* reqMethod = @"GET";

    //NSLog(@"graph request %@", nspath);

    if (params != Val_int(0)) {
        reqMethod = @"POST";

        value _params = Field(params, 0);
        value param;

        while (Is_block(_params)) {
            param = Field(_params, 0);
            NSString* key = [NSString stringWithCString:String_val(Field(param, 0)) encoding:NSUTF8StringEncoding];
            NSString* val = [NSString stringWithCString:String_val(Field(param, 1)) encoding:NSUTF8StringEncoding];
            [nsparams setValue:val forKey:key];
            _params = Field(_params, 1);
        }
    }

    value* _successCallbackGraphApi;
    value* _failCallbackGraphApi;
				
    REGISTER_CALLBACK(successCallback, _successCallbackGraphApi);
		if (_successCallbackGraphApi) {
			//NSLog(@"success callback is init in graphApi");
		} else {
			//NSLog(@"success callback is NOT init in graph");
		}
    REGISTER_CALLBACK(failCallback, _failCallbackGraphApi);

    // fbGraphrequest(nspath, nsparams, _successCallbackGraphApi, _failCallbackGraphApi);
    [FBRequestConnection startWithGraphPath:nspath parameters:nsparams HTTPMethod:reqMethod completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        //NSLog(@"completionHandler");

        if (error) {
            if (_failCallbackGraphApi) {
                caml_callback(*_failCallbackGraphApi, caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
            }
        } else {
            if (_successCallbackGraphApi) {
							NSError *jerr = nil;
							NSData *json = [NSJSONSerialization dataWithJSONObject:result options:0 error:&jerr];
							if (!jerr) {
								value mljs = caml_alloc_string(json.length);
								[json getBytes:String_val(mljs) length:json.length];
								caml_callback(*_successCallbackGraphApi,mljs);
							} else if (_failCallbackGraphApi) {
								caml_callback(*_failCallbackGraphApi,caml_copy_string([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
							}
                //FBSBJSON* json = [[FBSBJSON alloc] init];
                //NSError* err = nil;
                //NSString* jsonResult = [json stringWithObject:result error:&err];

							/*
                NSLog(@"jsonResult %@", jsonResult);

                if (err) {
                    if (_failCallbackGraphApi) {
                        caml_callback(*_failCallbackGraphApi, caml_copy_string([[err localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
                    }
                } else {
                    caml_callback2(*caml_named_value("fb_graphrequestSuccess"), caml_copy_string([jsonResult cStringUsingEncoding:NSUTF8StringEncoding]), *_successCallbackGraphApi);
                }

                [json release];
								*/
            }
        }

	    //NSLog(@"FREE SUCESSCALLBACK IN GRAPH API");
			FREE_CALLBACK(_successCallbackGraphApi);
			FREE_CALLBACK(_failCallbackGraphApi);        
    }];
}
