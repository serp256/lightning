#import "LightAppDelegate.h"
#import "LightViewController.h"
#import "FacebookSDK/FacebookSDK.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
#import <UIKit/UIDevice.h>
#import "common_ios.h"
#import <FBSDKCoreKit.h>
#import <FBSDKLoginKit.h>
#import <FBSDKShareKit.h>

#import "mlwrapper_ios.h"
#import "fbwrapper_ios.h"
static FBSDKLoginManager *loginManager;

@interface LightFBDialogDelegate : NSObject <FBWebDialogsDelegate>
{
	value* _successCallbackRequest;
	value* _failCallbackRequest;
}

- (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback;
@end


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


static FBSession* fbSession = nil;


void fbError(NSError* error) {
	caml_callback(*caml_named_value("fb_fail"), caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
}

NSMutableArray* readPermissions = nil;
NSMutableArray* publishPermissions = nil;


int extraPermsState = EXTRA_PERMS_NOT_REQUESTED;

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error);

// enum {
//     NotRequested,
//     ReadPermissionsRequsted,
//     PublishPermissionsRequsted,
// } extraPermsState = NotRequested;
// int extraPermsRequested = 0;

static inline void requestPublishPermissions();
static inline void requestReadPermissions();

BOOL readPermsRequested = NO;
BOOL publishPermsRequested = NO;

void (^publishPermsComplete)(FBSession *session,NSError *error) = ^(FBSession *session,NSError *error) {
    // some shit happens with this block: it called if only new publish permissions requested. if requsted both read and publish permissions -- called only requestNewReadPermissions completionHandler
    NSLog(@"requestPublishPermissions completionHandler");

    [publishPermissions removeAllObjects];
    [publishPermissions release];
    publishPermissions = nil;
    fbSession = session;
    [FBSession setActiveSession:session];
    // extraPermsState = NotRequested;
    // extraPermsRequested = 0;
    caml_callback(*caml_named_value("fb_success"), Val_unit);            
};

void (^readPermsCompelete)(FBSession *session,NSError *error) = ^(FBSession *session,NSError *error) {
    NSLog(@"requestReadPermissions completionHandler");

    [readPermissions removeAllObjects];
    [readPermissions release];
    readPermissions = nil;
    requestPublishPermissions();           
};

static inline void requestPublishPermissions() {
    publishPermsRequested = YES;

    if (publishPermissions && [publishPermissions count]) {
        NSLog(@"requesting additional publish permissions");
        // extraPermsState = PublishPermissionsRequsted;
        [[FBSession activeSession] requestNewPublishPermissions:publishPermissions defaultAudience:FBSessionDefaultAudienceEveryone completionHandler:publishPermsComplete];
    } else {
        NSLog(@"skip additional publish permissions");
        fbSession = [FBSession activeSession];
        // extraPermsState = NotRequested;
        caml_callback(*caml_named_value("fb_success"), Val_unit);
    }
}

static inline void requestReadPermissions() {
    readPermsRequested = YES;

    if (readPermissions && [readPermissions count]) {
        NSLog(@"requesting additional read permissions");
        // extraPermsState = ReadPermissionsRequsted;
        [[FBSession activeSession] requestNewReadPermissions:readPermissions completionHandler:readPermsCompelete];
    } else {
        NSLog(@"skip additional read permissions");
        requestPublishPermissions();
    }
}

void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error) {
    switch (state) {
        case FBSessionStateOpen: {
            NSLog(@"FBSessionStateOpen %d", [session.permissions count]);

            if (IOS6) {
                /* io6 doesn't call this function each time session change its state; insted it calls blocks which given in requestNewPublishPermissions and requestNewReadPermissions calls */
                requestReadPermissions();
            } else {
                /* ios7 ignores blocks from requestNewPublishPermissions and requestNewReadPermissions calls and calls this function each time session changes its state */
                if (publishPermsRequested) {
                    publishPermsComplete(session, error);
                } else if (readPermsRequested) {
                    readPermsCompelete(session, error);
                } else {
                    requestReadPermissions();
                }
            }            

            break;
        }


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
            break;
    }    
}

typedef void (^successBlockT) (void);

value ml_fbInit(value appId) {
	NSLog(@"ml_fbInit");
    [FBSDKSettings setAppID:[NSString stringWithCString:String_val(appId) encoding:NSASCIIStringEncoding]];
		FBSDKAccessToken *cachedToken = [[FBSDKSettings accessTokenCache] fetchAccessToken];
		[FBSDKAccessToken setCurrentAccessToken:cachedToken];

		loginManager = [[FBSDKLoginManager alloc] init];

    NSNotificationCenter* notifCntr = [NSNotificationCenter defaultCenter];

    [notifCntr addObserverForName:@"APP_DID_FINISH_LAUNCHING" object:nil queue:nil usingBlock:^(NSNotification* notif) {
        NSLog(@"iapp did finish launching");
				NSDictionary* data = [notif userInfo];
				UIApplication* app= [data objectForKey:@"APP"];
				NSDictionary* launchOptions = [data objectForKey:@"LAUNCH_OPTIONS"];

				[[FBSDKApplicationDelegate sharedInstance] application:app didFinishLaunchingWithOptions:launchOptions];
    }];

    [notifCntr addObserverForName:APP_OPENURL_SOURCEAPP object:nil queue:nil usingBlock:^(NSNotification* notif) {
        NSLog(@"handling application open url source");
				NSDictionary* data = [notif userInfo];
				NSURL* url = [data objectForKey:APP_URL_DATA];
				UIApplication* app= [data objectForKey:@"APP"];
				NSString* sourceApp = [data objectForKey:APP_SOURCEAPP_DATA];

        NSLog(@"token %@", ([FBSDKAccessToken currentAccessToken]));

				[[FBSDKApplicationDelegate sharedInstance] application:app openURL:url sourceApplication:sourceApp annotation:nil];
    }];

    [notifCntr addObserverForName:APP_BECOME_ACTIVE_NOTIFICATION object:nil queue:nil usingBlock:^(NSNotification* notif) {
        NSLog(@"----------handling application become active");
				[FBSDKAppEvents activateApp];
    }];    
		return Val_unit;
}

//void fbConnect (FBSession* session, FBSessionState state, NSError* error);

void resetPermissions () {
		extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
		/*
		if (readPermissions) {
			[readPermissions removeAllObjects];
			[readPermissions release];
			readPermissions = nil;
		}
		if (publishPermissions) {
			[publishPermissions removeAllObjects];
			[publishPermissions release];
			publishPermissions = nil;
		}
		*/
}
value parsePermissions(value permissions) {
    NSLog(@"parsePermissions");

		extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
		if (readPermissions) {
			[readPermissions removeAllObjects];
			[readPermissions release];
			readPermissions = nil;
		}
		if (publishPermissions) {
			[publishPermissions removeAllObjects];
			[publishPermissions release];
			publishPermissions = nil;
		}

		//resetPermissions ();

    if (permissions != Val_int(0)) {        
        NSLog(@"parsing permission list");
        NSArray* publish_permissions = [NSArray arrayWithObjects:@"publish_actions", @"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", nil];
        value perms = Field(permissions, 0);

        while (Is_block(perms)) {
            NSString* nsperm = [NSString stringWithCString:(String_val(Field(perms, 0))) encoding:NSASCIIStringEncoding];

            NSLog(@"permission %@", nsperm);

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
}
void checkPermissions (value *fail, value *success, successBlockT successCallback) {
	CAMLparam0();
	NSLog(@"check permissions; state %@, %@, %d", readPermissions, publishPermissions, extraPermsState);
	void (^failBlock)(char*) =^ (char* msg) {
		resetPermissions ();
		if (fail) {
			RUN_CALLBACK(fail, caml_copy_string (msg));
			FREE_CALLBACK(success);
			FREE_CALLBACK(fail);        
		}
		else {
			caml_callback(*caml_named_value("fb_fail"), caml_copy_string (msg));
		}
	};
	void (^successBlock)(void) = ^{
		resetPermissions ();
		if (successCallback) {
			successCallback ();
		}
		else {
			caml_callback(*caml_named_value("fb_success"), Val_unit);
		}
	};
	if ([FBSDKAccessToken currentAccessToken]) {
    switch (extraPermsState) {
				case EXTRA_PERMS_NOT_REQUESTED: {
						bool readPermissionsChecked = YES;
								if (readPermissions) {
									for (NSString *nsperm in readPermissions)
									{
										NSLog(@"check permission granted %@", nsperm);
										if (![[FBSDKAccessToken currentAccessToken] hasGranted:nsperm]) {
											FBSDKLoginManagerRequestTokenHandler handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
															NSLog(@"result %@", result);
															if (error) {
																NSLog(@"error %@", error);
																failBlock ([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
																/*
																resetPermissions ();
																fbError (error);
																*/
															} else if (result.isCancelled) {
																/*
																resetPermissions ();
																caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB Authorization cancelled"));
																*/
																failBlock ("FB Authorization cancelled");
															} else {
																NSLog(@"FB login success");
																extraPermsState = READ_PERMS_REQUESTED;
																checkPermissions (fail, success, successCallback);
															}};

											[loginManager logInWithReadPermissions:readPermissions handler:handler];
											readPermissionsChecked= NO;
											break;
										}
									}
								}
								if (readPermissionsChecked) {
									extraPermsState = READ_PERMS_REQUESTED;
									checkPermissions (fail, success, successCallback);
								}
								break;
						}
			case READ_PERMS_REQUESTED: {
						bool readPermissionsChecked = YES;
								if (readPermissions) {
									for (NSString *nsperm in readPermissions)
									{
										NSLog(@"2 check permission granted %@", nsperm);
										if (![[FBSDKAccessToken currentAccessToken] hasGranted:nsperm]) {
											readPermissionsChecked= NO;
											break;
										}
									}
								}
								if (readPermissionsChecked) {
									extraPermsState = PUBLISH_PERMS_REQUESTED;
									bool publishPermissionsChecked = YES;
											if (publishPermissions) {
												for (NSString *nsperm in publishPermissions)
												{
													NSLog(@"check permission granted %@", nsperm);
													if (![[FBSDKAccessToken currentAccessToken] hasGranted:nsperm]) {
														FBSDKLoginManagerRequestTokenHandler handler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
																		NSLog(@"result %@", result);
																		if (error) {
																			NSLog(@"error %@", error);
																			failBlock ([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
																			/*
																				resetPermissions ();
																				fbError (error);
																				*/
																		} else if (result.isCancelled) {
																			/*
																				resetPermissions ();
																				caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB Authorization cancelled"));
																				*/
																			failBlock ("FB Authorization cancelled");
																		} else {
																			NSLog(@"FB login success");
																			extraPermsState = PUBLISH_PERMS_REQUESTED;
																			checkPermissions (fail, success, successCallback);
																		}
														};

														[loginManager logInWithPublishPermissions:publishPermissions handler:handler];

														publishPermissionsChecked= NO;
														break;
													}
												}
											}
											if (publishPermissionsChecked) {
												/*
												resetPermissions ();
												caml_callback(*caml_named_value("fb_success"), Val_unit);
												*/
												successBlock ();
											}
								}
								else {
									/*
									resetPermissions ();
									caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB check read permissions failed"));
									*/
									failBlock ("FB check read permissions failed");
								}
						 break;
					 }
			case PUBLISH_PERMS_REQUESTED: {
					bool publishPermissionsChecked = YES;
							if (publishPermissions) {
								for (NSString *nsperm in publishPermissions)
								{
									NSLog(@"check permission granted %@", nsperm);
									publishPermissionsChecked = NO; 
									break;
								}
							}
							resetPermissions ();
							if (publishPermissionsChecked) {
								successBlock ();
								/*
								caml_callback(*caml_named_value("fb_success"), Val_unit);
								*/
							}
							else {
								/*
								caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB Authorization failed"));
								*/

								failBlock ("FB Authorization failed");
							}
						break;
					}
		}
	}
	else {
		/*
		resetPermissions ();
		caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB Authorization failed"));
		*/
		failBlock ("FB Authorization failed");
	}
	CAMLreturn0;
}

void reconnect (value* failGraphRequest, value* successGraphRequest, successBlockT successBlock) {
	CAMLparam0();
    NSLog(@"fb reconnect");
		NSLog(@"token %@", ([[FBSDKAccessToken currentAccessToken] tokenString]));

		[loginManager logInWithReadPermissions:readPermissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			NSLog(@"result %@", result);
			if (error) {
				NSLog(@"error %@", error);
				RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
			} else if (result.isCancelled) {
				NSLog(@"fb auth cancelled");
				RUN_CALLBACK(failGraphRequest, caml_copy_string ("Fail reconnect: cancel"));
				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
			} else {
				NSLog(@"token1 %@", ([[FBSDKAccessToken currentAccessToken] tokenString]));
				FBSDKAccessToken *cachedToken = [[FBSDKSettings accessTokenCache] fetchAccessToken];
				NSLog(@"token2 %@", ([cachedToken tokenString]));
				checkPermissions (failGraphRequest,successGraphRequest,successBlock);
			}
		}];
	 CAMLreturn0;
}

value ml_fbConnect(value permissions) {
    NSLog(@"ml_fbConnect");

		parsePermissions (permissions);

   if ([FBSDKAccessToken currentAccessToken]) {
		 NSLog(@"already authorized");
		 checkPermissions (nil, nil, nil);
	 }
	 else {
		 NSLog(@"authorize");
		 
		[loginManager logInWithReadPermissions:readPermissions handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			NSLog(@"result %@", result);
			if (error) {
				NSLog(@"error %@", error);
				fbError (error);
			} else if (result.isCancelled) {
				NSLog(@"fb auth cancelled");
				caml_callback (*caml_named_value("fb_fail"), caml_copy_string ("FB Authorization cancelled"));
			} else {
				NSLog(@"FB login success");
				checkPermissions (nil,nil,nil);
			}
		}];
	 }
	 return Val_unit;
}

value ml_fbDisconnect(value connect) {
	NSLog(@"ml_fbDisConnect");
	if (loginManager) {
		NSLog(@"logout");
		[loginManager logOut];
	}
	return Val_unit;
}

value ml_fbLoggedIn (value unit) {

   if ([FBSDKAccessToken currentAccessToken]) {
		 return (Val_bool (1));
	 }
	 else {
		 return (Val_bool (0));
	 }
}

value ml_fbAccessToken(value unit) {
   if ([FBSDKAccessToken currentAccessToken]) {
    return caml_copy_string([[[FBSDKAccessToken currentAccessToken] tokenString] cStringUsingEncoding:NSASCIIStringEncoding]);
	 }
	 else
		 return caml_copy_string("");
}
void appRequest (NSString* nstitle, NSString* nsmessage, NSDictionary* nsparams, value* successAppRequest, value* failAppRequest) {
			//"http://cs543109.vk.me/v543109554/73bf/q1qfvxmppFE.jpg"
			//
			FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
			content.actionType = @"send";
			content.message= nsmessage;
			content.title= nstitle;
			content.to= [NSArray arrayWithObject:[nsparams objectForKey:@"to"]];

			[FBSDKGameRequestDialog showWithContent:content delegate:nil];

	/*
			FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
			content.contentURL = [NSURL URLWithString:nsmessage];
			[FBSDKShareDialog showFromViewController:[LightViewController sharedInstance] withContent:content delegate:nil];
			*/
				RUN_CALLBACK(failAppRequest, caml_copy_string ("FB Authorization cancelled"));
				FREE_CALLBACK(successAppRequest);
				FREE_CALLBACK(failAppRequest);        
	/*
		//[[LightViewController sharedInstance] resignActive];
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

		*/
}

value ml_fbApprequest(value vtitle, value vmessage, value vrecipient, value vdata, value vsuccess, value vfail) {

		//CAMLparam5(vtitle, vmessage, vrecipient, vsuccess, vfail);
		//CAMLparam1(vdata);
		CAMLlocal2(_params,param);

		value *failAppRequest, *successAppRequest;
		REG_OPT_CALLBACK(vsuccess, successAppRequest);
		REG_OPT_CALLBACK(vfail, failAppRequest);

    NSString* nstitle = [NSString stringWithCString:String_val(vtitle) encoding:NSUTF8StringEncoding];
    NSString* nsmessage = [NSString stringWithCString:String_val(vmessage) encoding:NSUTF8StringEncoding];


		NSMutableDictionary *nsparams = [NSMutableDictionary dictionaryWithCapacity:2];

    if (Is_block(vrecipient)) {
        NSString* nsrecipient = [NSString stringWithCString:String_val(Field(vrecipient, 0)) encoding:NSUTF8StringEncoding];
        [nsparams setObject:nsrecipient forKey:@"to"];
    }

    if (Is_block(vdata)) {
        NSString* nsdata = [NSString stringWithCString:String_val(Field(vdata, 0)) encoding:NSUTF8StringEncoding];
        [nsparams setObject:nsdata forKey:@"data"];
    }
		NSLog(@"app request to: %@ message: %@ data: %@", nstitle, nsmessage, nsparams);

   if ([FBSDKAccessToken currentAccessToken]) {
		 NSLog(@"already authorized");
		 appRequest (nstitle, nsmessage, nsparams, successAppRequest, failAppRequest);
	 }
	 else {
		[loginManager logInWithReadPermissions:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			NSLog(@"result %@", result);
			if (error) {
				NSLog(@"error %@", error);
				RUN_CALLBACK(failAppRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(successAppRequest);
				FREE_CALLBACK(failAppRequest);        
			} else if (result.isCancelled) {
				// Handle cancellations
				NSLog(@"fb auth cancelled");
				RUN_CALLBACK(failAppRequest, caml_copy_string ("FB Authorization cancelled"));
				FREE_CALLBACK(successAppRequest);
				FREE_CALLBACK(failAppRequest);        
			} else {
				NSLog(@"FB login success");
				appRequest (nstitle, nsmessage, nsparams, successAppRequest, failAppRequest);
			}
		}];
	 }
	 return Val_unit;

}

void ml_fbApprequest_byte(value * argv, int argn) {}

void (^_graphRequest) (NSString*, NSDictionary*, NSString*, value*, value*) = ^(NSString* nspath, NSDictionary* nsparams, NSString* reqMethod, value* successGraphRequest, value* failGraphRequest) {
		NSLog(@"^^graph token %@", ([[FBSDKAccessToken currentAccessToken] tokenString]));
		FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:nspath parameters:nsparams HTTPMethod:reqMethod];
			[request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
				CAMLparam0();
				CAMLlocal1(mljs);
				NSLog(@"^^^completionHandler err %@ result %@", error, result);

				if (error) {
					RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
				} else {
						if (successGraphRequest) {
							NSError *jerr = nil;
							NSData *json = [NSJSONSerialization dataWithJSONObject:result options:0 error:&jerr];
							if (!jerr) {
								value mljs = caml_alloc_string(json.length);
								[json getBytes:String_val(mljs) length:json.length];
								RUN_CALLBACK(successGraphRequest, mljs);
							} else {
								RUN_CALLBACK(failGraphRequest, caml_copy_string ([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
							}
						}
				}

				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
				CAMLreturn0;
		}];
};

void graphRequest (NSString* nspath, NSDictionary* nsparams, value* successGraphRequest, value* failGraphRequest, NSString* reqMethod) {
		NSLog(@"graph token %@", ([[FBSDKAccessToken currentAccessToken] tokenString]));
			[[[FBSDKGraphRequest alloc] initWithGraphPath:nspath parameters:nsparams HTTPMethod:reqMethod] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
				CAMLparam0();
				CAMLlocal1(mljs);
        NSLog(@"!!!!completionHandler err %@ result %@", error, result);

        if (error) {
					NSLog(@"ERROR %@", [error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode]);
					//FBSDKGraphRequestErrorGraphErrorCode
					if ([[error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode] intValue] == 2500) {
									successBlockT block = ^ {
										_graphRequest (nspath, nsparams, reqMethod, successGraphRequest, failGraphRequest);
									};
									reconnect (failGraphRequest, successGraphRequest, block);
						}
					else {
						RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
						FREE_CALLBACK(successGraphRequest);
						FREE_CALLBACK(failGraphRequest);        
					}
        } else {
            if (successGraphRequest) {
							NSError *jerr = nil;
							NSData *json = [NSJSONSerialization dataWithJSONObject:result options:0 error:&jerr];
							if (!jerr) {
								value mljs = caml_alloc_string(json.length);
								[json getBytes:String_val(mljs) length:json.length];
								RUN_CALLBACK(successGraphRequest, mljs);
							} else {
								RUN_CALLBACK(failGraphRequest, caml_copy_string ([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
							}
            }
					FREE_CALLBACK(successGraphRequest);
					FREE_CALLBACK(failGraphRequest);        
        }

				CAMLreturn0;
    }];
}

value ml_fbGraphrequest(value vpath, value vparams, value vsuccess, value vfail, value vhttp_method) {
		CAMLparam5(vpath, vparams, vfail, vsuccess, vhttp_method);
		CAMLlocal2(_params,param);

		value *failGraphRequest, *successGraphRequest;
		REG_OPT_CALLBACK(vsuccess, successGraphRequest);
		REG_OPT_CALLBACK(vfail, failGraphRequest);

    NSString* nspath = [NSString stringWithCString:String_val(vpath) encoding:NSASCIIStringEncoding];
    NSDictionary* nsparams = [NSMutableDictionary dictionary];
    NSLog(@"graph request %@", nspath);

    if (vparams != Val_int(0)) {

        value _params = Field(vparams, 0);
        value param;

        while (Is_block(_params)) {
            param = Field(_params, 0);
            NSString* key = [NSString stringWithCString:String_val(Field(param, 0)) encoding:NSUTF8StringEncoding];
            NSString* val = [NSString stringWithCString:String_val(Field(param, 1)) encoding:NSUTF8StringEncoding];
            [nsparams setValue:val forKey:key];
            _params = Field(_params, 1);
        }
    }

    static value get_variant = 0;
    if (!get_variant) get_variant = caml_hash_variant("get");

    NSString* reqMethod = get_variant == vhttp_method ? @"GET" : @"POST";

		graphRequest (nspath, nsparams, successGraphRequest, failGraphRequest, reqMethod);

		/*
   if ([FBSDKAccessToken currentAccessToken]) {
		 NSLog(@"already authorized");
		 graphRequest (nspath, nsparams, successGraphRequest, failGraphRequest, reqMethod);
	 }
	 else {
		[loginManager logInWithReadPermissions:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			NSLog(@"result %@", result);
			if (error) {
				NSLog(@"error %@", error);
				RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
			} else if (result.isCancelled) {
				// Handle cancellations
				NSLog(@"fb auth cancelled");
				RUN_CALLBACK(failGraphRequest, caml_copy_string ("FB Authorization cancelled"));
				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
			} else {
				NSLog(@"FB login success");
				graphRequest (nspath, nsparams, successGraphRequest, failGraphRequest, reqMethod);
			}
		}];
	 }
	 */
	 return Val_unit;
}

value ml_fb_share_pic_using_native_app(value v_fname, value v_text) {
    return Val_false;
}

void fb_upload_photo_req(UIImage* img, NSString* text, value* success, value* fail) {
    NSLog(@"fb_upload_photo_req call");

    FBRequest* req = [FBRequest requestForUploadPhoto:img];
    [req.parameters setValue:text forKey:@"message"];
    [req startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"complete handler %@", error);

        if (!error) {
            NSLog(@"result %@", result);

            if (success) caml_callback(*success, Val_unit);
        } else {
            if (fail) caml_callback(*fail, caml_copy_string([[error localizedDescription] UTF8String]));
        }

        FREE_CALLBACK(success);
        FREE_CALLBACK(fail);
    }];
}

value ml_fb_share_pic(value v_success, value v_fail, value v_fname, value v_text) {
    CAMLparam4(v_fname, v_text, v_success, v_fail);

    value* success;
    value* fail;

    REGISTER_CALLBACK(v_success, success);
    REGISTER_CALLBACK(v_fail, fail);

    // NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:String_val(v_fname)] ofType:nil];
    NSString* path = [NSString stringWithUTF8String:String_val(v_fname)];
    __block UIImage* img = [UIImage imageWithContentsOfFile:path];
	__block BOOL handlerCalled = NO;
    __block NSString* text = [NSString stringWithUTF8String:String_val(v_text)];

    BOOL displayedNativeDialog = [FBDialogs
        presentOSIntegratedShareDialogModallyFrom:[LightViewController sharedInstance]
        initialText:text
        image:img
        url:nil
        handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
            NSLog(@"share pic handler err %@", error);

            if (!error) {
                switch (result) {
                    case FBOSIntegratedShareDialogResultSucceeded:
                        if (success) caml_callback(*success, Val_unit);
                        break;

                    case FBOSIntegratedShareDialogResultCancelled:
                        if (fail) caml_callback(*fail, caml_copy_string("cancelled"));
                        break;

                    case FBOSIntegratedShareDialogResultError:
                        if (fail) caml_callback(*fail, caml_copy_string("cancelled"));
                        break;
                }                
            } else {
                NSLog(@"call upload photo from block");

                [[LightViewController sharedInstance] becomeActive];
                fb_upload_photo_req(img, text, success, fail);                
                // if (fail) caml_callback(*fail, caml_copy_string([[error localizedDescription] UTF8String]));
            }

/*            FREE_CALLBACK(success);
            FREE_CALLBACK(fail);*/
						
			handlerCalled = YES;
        }];

    if (!displayedNativeDialog && !handlerCalled) {

        NSLog(@"call upload photo outside block");
        fb_upload_photo_req(img, text, success, fail);
        // if (fail) caml_callback(*fail, caml_copy_string("cannot display dialog"));

/*        FREE_CALLBACK(success);
        FREE_CALLBACK(fail);*/
    }

    CAMLreturn(Val_unit);
}

/*
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
   return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}
*/
