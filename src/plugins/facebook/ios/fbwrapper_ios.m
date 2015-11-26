#import "LightAppDelegate.h"
#import "LightFacebookDelegate.h"
#import "LightViewController.h"
//#import "FacebookSDK/FacebookSDK.h"
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
/*
@interface LightFBDialogDelegate : NSObject <FBWebDialogsDelegate>
{
	value* _successCallbackRequest;
	value* _failCallbackRequest;
}

- (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback;
@end
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


//static FBSession* fbSession = nil;


void fbError(NSError* error) {
	caml_callback(*caml_named_value("fb_fail"), caml_copy_string([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
}

NSMutableArray* readPermissions = nil;
NSMutableArray* publishPermissions = nil;


int extraPermsState = EXTRA_PERMS_NOT_REQUESTED;

//void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error);

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
/*
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

*/
/*
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
*/
/*
void sessionStateChanged(FBSession* session, FBSessionState state, NSError* error) {
    switch (state) {
        case FBSessionStateOpen: {
            if (IOS6) {
                // io6 doesn't call this function each time session change its state; insted it calls blocks which given in requestNewPublishPermissions and requestNewReadPermissions calls 
                requestReadPermissions();
            } else {
                // ios7 ignores blocks from requestNewPublishPermissions and requestNewReadPermissions calls and calls this function each time session changes its state 
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
*/
typedef void (^successBlockT) (void);
typedef void (^graphResponseHandler) (value*, value*, id);

value ml_fbInit(value appId) {
	NSLog(@"ml_fbInit");
    [FBSDKSettings setAppID:[NSString stringWithCString:String_val(appId) encoding:NSASCIIStringEncoding]];
		[FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
		NSLog( @"running FB sdk version: %@", [FBSDKSettings sdkVersion] );

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

void resetPermissions () {
		extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
}

void parsePermissions(value permissions) {
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
void getProfile (void) {
	if (![FBSDKProfile	currentProfile]) {
		NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name,link";
		FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:nil ];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      FBSDKProfile *profile = nil;
      if (!error) {
        profile = [[FBSDKProfile alloc] initWithUserID:result[@"id"]
                                             firstName:result[@"first_name"]
                                            middleName:result[@"middle_name"]
                                              lastName:result[@"last_name"]
                                                  name:result[@"name"]
                                               linkURL:[NSURL URLWithString:result[@"link"]]
                                           refreshDate:[NSDate date]];
       [FBSDKProfile setCurrentProfile:profile];
			 caml_callback(*caml_named_value("fb_success"), Val_unit);
      }
			else {
				caml_callback(*caml_named_value("fb_fail"), caml_copy_string ([[error localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
			}
    }];
	}
	else {
		caml_callback(*caml_named_value("fb_success"), Val_unit);
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
			getProfile();
			//caml_callback(*caml_named_value("fb_success"), Val_unit);
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
																failBlock ((char*)[[error localizedDescription] UTF8String]);
															} else if (result.isCancelled) {
																NSLog(@"cancel");
																failBlock ("FB Authorization cancelled");
																[[LightViewController sharedInstance] becomeActive];
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
																			failBlock ((char*)[[error localizedDescription] UTF8String]);
																		} else if (result.isCancelled) {
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
												successBlock ();
											}
								}
								else {
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
							}
							else {
								failBlock ("FB Authorization failed");
							}
						break;
					}
		}
	}
	else {
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
				[[LightViewController sharedInstance] becomeActive];
				FREE_CALLBACK(successGraphRequest);
				FREE_CALLBACK(failGraphRequest);        
			} else {
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
				[[LightViewController sharedInstance] becomeActive];
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

void appRequest (NSString* nstitle, NSString* nsmessage, NSDictionary* nsparams, value* success, value* fail) {
	PRINT_DEBUG ("ios apprequest");
	FBSDKGameRequestDialog *gameRequestDialog = [[FBSDKGameRequestDialog alloc] init];
	FBSDKGameRequestContent *content = [[FBSDKGameRequestContent alloc] init];
	content.title = nstitle;
	content.message = nsmessage;
	content.to = [NSArray arrayWithObject:[nsparams objectForKey:@"to"]];
	content.data = [nsparams objectForKey:@"data"];
	//apprequestDelegate = [[LightFBAppRequestDelegate alloc] initWithSuccess:success andFail:fail]; 
	gameRequestDialog.content = content;
	[gameRequestDialog show];

	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
			//"http://cs543109.vk.me/v543109554/73bf/q1qfvxmppFE.jpg"
			//
	/*
			FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
			content.contentURL = [NSURL URLWithString:nsmessage];
			[FBSDKShareDialog showFromViewController:[LightViewController sharedInstance] withContent:content delegate:nil];
			*/
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
		CAMLparam5(vtitle, vmessage, vrecipient, vdata, vsuccess);
		CAMLxparam1(vfail);
		CAMLlocal2(_params,param);
		PRINT_DEBUG ("ml_fbApprequest");

		value *success, *fail;
		REG_OPT_CALLBACK(vsuccess, success);
		REG_OPT_CALLBACK(vfail, fail);

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
		 appRequest (nstitle, nsmessage, nsparams, success, fail);
	 }
	 else {
		[loginManager logInWithReadPermissions:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
			NSLog(@"result %@", result);
			if (error) {
				NSLog(@"error %@", error);
				RUN_CALLBACK(fail, caml_copy_string ([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(success);
				FREE_CALLBACK(fail);        
			} else if (result.isCancelled) {
				// Handle cancellations
				NSLog(@"fb auth cancelled");
				RUN_CALLBACK(fail, caml_copy_string ("FB Authorization cancelled"));
				[[LightViewController sharedInstance] becomeActive];
				FREE_CALLBACK(success);
				FREE_CALLBACK(fail);        
			} else {
				NSLog(@"FB login success");
				appRequest (nstitle, nsmessage, nsparams, success, fail);
			}
		}];
	 }
	 CAMLreturn(Val_unit);
}

value ml_fbApprequest_byte(value * argv, int argn) {
	return ml_fbApprequest (argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

/*
@interface LightDelegate: NSObject <FBSDKGraphRequestConnectionDelegate> { 
	NSArray* res;
	graphResponseHandler h;
	value* success;
	value* fail;
}
- (id)init:(NSArray*) results handler:(graphResponseHandler) handler success:(value*) s fail:(value*) f;
- (void)requestConnectionDidFinishLoading:(FBSDKGraphRequestConnection *)connection;
- (void)requestConnection:(FBSDKGraphRequestConnection *)connection
         didFailWithError:(NSError *)error;
- (void)requestConnection:(FBSDKGraphRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;
@end
@implementation LightDelegate 
- (id) init:(NSArray*) results handler:(graphResponseHandler) handler success:(value*) s fail:(value*) f{
	self = [super init];
	res = results;
	h = handler;
	success = s;
	fail = f;
	return self;
}
- (void)requestConnectionDidFinishLoading:(FBSDKGraphRequestConnection *)connection {
	NSLog (@"DID finish");
	//h (success,fail,res);

}
- (void)requestConnection:(FBSDKGraphRequestConnection *)connection
         didFailWithError:(NSError *)error {}
- (void)requestConnection:(FBSDKGraphRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {}

@end

*/
void (^_graphRequest) (NSArray*, NSDictionary*, NSString*, value*, value*, graphResponseHandler) = ^(NSArray* nspaths, NSDictionary* nsparams, NSString* reqMethod, value* successGraphRequest, value* failGraphRequest, graphResponseHandler handler) {
	FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
	NSMutableArray* results = [[NSMutableArray alloc] init];
	//connection.delegate = [[LightDelegate alloc] init:results handler:handler success:successGraphRequest fail:failGraphRequest];
	__block int answersCount  = 0;
	__block NSError* err;
	void (^completionHandlerBlock)(FBSDKGraphRequestConnection*, id, NSError*)= ^(FBSDKGraphRequestConnection *connection, id result, NSError *error){
        if (error) {
					NSLog(@"ERROR %@ %@", error, [error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode]);
					//user cancel native reauth window
					if ([[error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode] intValue] == 2500) {
						[connection cancel];
						RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
						FREE_CALLBACK(successGraphRequest);
						FREE_CALLBACK(failGraphRequest);        
						}
					else {
						answersCount += 1;
						err = error;
						if (answersCount == nspaths.count && handler) { 
							handler (successGraphRequest, failGraphRequest, results);
						}
					}
        } else {
					answersCount += 1;
					[results addObject:result];
					if (answersCount == nspaths.count && handler) { 
						handler (successGraphRequest, failGraphRequest, results);
					}
        }
	};
	for (id path in nspaths) {
		NSLog(@"path %@", path);
		FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:nsparams];
		[connection addRequest:request completionHandler:completionHandlerBlock];
	}
	[connection start];
};

void graphRequest (NSArray* nspaths, NSDictionary* nsparams, value* successGraphRequest, value* failGraphRequest, NSString* reqMethod, graphResponseHandler handler) {
	FBSDKGraphRequestConnection *connection = [[FBSDKGraphRequestConnection alloc] init];
	NSMutableArray* results = [[NSMutableArray alloc] init];
	//connection.delegate = [[LightDelegate alloc] init:results handler:handler success:successGraphRequest fail:failGraphRequest];
	__block int answersCount  = 0;
	__block NSError* err;
	void (^completionHandlerBlock)(FBSDKGraphRequestConnection*, id, NSError*)= ^(FBSDKGraphRequestConnection *connection, id result, NSError *error){
        if (error) {
					NSLog(@"ERROR %@ %@", error, [error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode]);
					//user cancel native reauth window
					int errCode = [[error.userInfo valueForKey:FBSDKGraphRequestErrorGraphErrorCode] intValue];
					if (errCode == 104 || errCode == 2500) {
						[connection cancel];
									successBlockT block = ^ {
										_graphRequest (nspaths, nsparams, reqMethod, successGraphRequest, failGraphRequest, handler);
									};
									reconnect (failGraphRequest, successGraphRequest, block);
						}
					else {
						answersCount += 1;
						err = error;
						if (answersCount == nspaths.count && handler) { 
							if (results.count > 0) {
								handler (successGraphRequest, failGraphRequest, results);
							}
							else {
								RUN_CALLBACK(failGraphRequest, caml_copy_string ([[error localizedDescription] UTF8String]));
								FREE_CALLBACK(successGraphRequest);
								FREE_CALLBACK(failGraphRequest);        
							}
						}
					}
        } else {
					answersCount += 1;
					NSLog (@"result %@ %d", result, answersCount);
					[results addObject:result];
					if (answersCount == nspaths.count && handler) { 
						handler (successGraphRequest, failGraphRequest, results);
					}
        }
	};
	for (id path in nspaths) {
		NSLog(@"path %@", path);
		FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:nsparams];
		[connection addRequest:request completionHandler:completionHandlerBlock];
	}
	[connection start];
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

		graphResponseHandler handler = ^ (value* success, value* fail, id result) {
			CAMLparam0();
			CAMLlocal1(mljs);
			NSError *jerr = nil;
			NSData *json = [NSJSONSerialization dataWithJSONObject:result options:0 error:&jerr];
			if (!jerr) {
				value mljs = caml_alloc_string(json.length);
				[json getBytes:String_val(mljs) length:json.length];
				RUN_CALLBACK(success, mljs);
			} else {
				RUN_CALLBACK(fail, caml_copy_string ([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
			}
			CAMLreturn0;
		};

		graphRequest ([NSArray arrayWithObjects:nspath,nil], nsparams, successGraphRequest, failGraphRequest, reqMethod, handler);

		CAMLreturn(Val_unit);
}

/*
value ml_fb_share_pic_using_native_app(value v_fname, value v_text) {
    return Val_false;
}
*/

void fb_upload_photo_req(UIImage* img, NSString* text, value* success, value* fail) {
	NSLog(@"fb_upload_photo_req: not implemented yet");

		/*
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
		*/
}

value ml_fb_share_pic(value v_success, value v_fail, value v_fname, value v_text) {
    CAMLparam4(v_fname, v_text, v_success, v_fail);

		NSLog(@"fb_share_pic: not implemented yet");
    value* success;
    value* fail;

    REGISTER_CALLBACK(v_success, success);
    REGISTER_CALLBACK(v_fail, fail);

		/*
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

						
			handlerCalled = YES;
        }];

    if (!displayedNativeDialog && !handlerCalled) {

        NSLog(@"call upload photo outside block");
        fb_upload_photo_req(img, text, success, fail);
        // if (fail) caml_callback(*fail, caml_copy_string("cannot display dialog"));

    }

		*/
            FREE_CALLBACK(success);
            FREE_CALLBACK(fail);
    CAMLreturn(Val_unit);
}

value ml_fb_share(value v_text, value v_link, value v_picUrl, value v_success, value v_fail, value unit) {
    CAMLparam5(v_text, v_link, v_picUrl, v_success, v_fail);

		NSString* nstext = Is_block (v_text) ? [NSString stringWithCString:String_val(Field(v_text,0)) encoding:NSASCIIStringEncoding]: nil;
		NSURL* nsurl = Is_block (v_link) ? [NSURL URLWithString:[NSString stringWithCString:String_val(Field(v_link,0)) encoding:NSASCIIStringEncoding]]: nil;
		NSURL* nspicUrl = Is_block (v_picUrl) ? [NSURL URLWithString:[NSString stringWithCString:String_val(Field(v_picUrl,0)) encoding:NSASCIIStringEncoding]]: nil;

		FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
		content.contentURL = nsurl;
		content.imageURL = nspicUrl;
		content.contentTitle = nstext;
		[FBSDKShareDialog showFromViewController:[LightViewController sharedInstance] withContent:content delegate:[[LightFacebookDelegate alloc] initWithSuccess:v_success andFail:v_fail] ];

		CAMLreturn(Val_unit);
}

value ml_fb_share_byte(value* argv, int argn) {
    return ml_fb_share(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

value ml_fbUid (value unit) {
	return [FBSDKProfile	currentProfile]? (caml_copy_string([[FBSDKProfile	currentProfile].userID UTF8String])) : caml_copy_string("");
}

static value *create_user = NULL;

graphResponseHandler handler = ^ (value* success, value* fail, id result) {
	CAMLparam0();
	CAMLlocal2(vitems, head);
	if([result isKindOfClass:[NSArray class]] ) {
		NSArray *friendsInfo;
		NSArray *res = (NSArray *) result;

	if(res.count == 1 ) {

		@try {
			NSError *jerr = nil;
			NSData *nsdata= [NSJSONSerialization dataWithJSONObject:res[0] options:0 error:&jerr];
			if (!jerr) {
				NSDictionary *nsdict= [NSJSONSerialization JSONObjectWithData:nsdata options:0 error:&jerr];
				if (!jerr) {
					NSLog (@"1");
					friendsInfo = [nsdict objectForKey:@"data"];
				}
				else {
					RUN_CALLBACK(fail, caml_copy_string ([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
				}
				}		
			else {
				RUN_CALLBACK(fail, caml_copy_string ([[jerr localizedDescription] cStringUsingEncoding:NSUTF8StringEncoding]));
			} 
		}
	
		@catch (NSException *exc) {
				NSLog (@"2");
				friendsInfo = res;
			}

  }
	else { 
		friendsInfo = res;
	}
	if (friendsInfo == nil) {
		friendsInfo = res;
	}




	NSLog (@"loop %@", friendsInfo);
			int err = 0;

			do {
				if (friendsInfo== nil) {
					err = 1;
					break;
				}

				vitems = Val_int(0);

				for (id item in friendsInfo) {
					NSDictionary* mitem = item;

					NSString* mid = [mitem objectForKey:@"id"];
					NSString* mname = [mitem objectForKey:@"name"];
					NSString* mgender = [mitem objectForKey:@"gender"];
					NSDictionary* mpic = [mitem objectForKey:@"picture"];
					NSDictionary* mpicData = [mpic objectForKey:@"data"];
					NSString* mphoto = [mpicData objectForKey:@"url"];
					double lastSeenTime = 0;

					if (!(mid && mname )) {
						err = 1;
						break;
					}

					head = caml_alloc_tuple(2);
					value args[6] = { caml_copy_string([mid UTF8String]), caml_copy_string([mname UTF8String]), Val_int( [mgender isEqualToString:@"female"] ? 1: [mgender isEqualToString:@"male"] ? 2: 0),
										caml_copy_string([mphoto UTF8String]), Val_false, caml_copy_double(lastSeenTime)};
					Store_field(head, 0, caml_callbackN(*create_user, 6, args));
					Store_field(head, 1, vitems);

					vitems = head;
				}
			} while(NO);

			if (!err) {
				RUN_CALLBACK(success, vitems)
			} else {
				RUN_CALLBACK(fail, caml_copy_string("wrong format of response on friends request"));
			}

	}
	else {
				RUN_CALLBACK(fail, caml_copy_string("wrong format of response on friends request"));
	}
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);        
	CAMLreturn0;
};

value ml_fbFriends(value vinvitable, value vfail, value vsuccess) {
	CAMLparam3(vinvitable, vfail, vsuccess);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	if (!create_user) create_user = caml_named_value("create_user");

	NSDictionary* params= [NSDictionary dictionaryWithObjectsAndKeys: @"gender,id,name,picture", @"fields", nil];
	NSString* nspath = vinvitable == Val_true ? @"me/invitable_friends" : @"me/friends";
	graphRequest ([NSArray arrayWithObjects:nspath ,nil], params, success, fail, @"GET", handler);

  CAMLreturn(Val_unit);
}

value ml_fbUsers(value vfail, value vsuccess, value vids) {
	CAMLparam2(vfail, vsuccess);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	if (!create_user) create_user = caml_named_value("create_user");

	NSDictionary* params= [NSDictionary dictionaryWithObjectsAndKeys: @"gender,id,name,picture", @"fields", nil];
	NSString *nsids = [NSString stringWithUTF8String:String_val(vids)];
	NSArray *nspaths= [nsids componentsSeparatedByString: @","];
	NSLog (@"paths %@", nspaths);
	graphRequest (nspaths, params, success, fail, @"GET", handler);

  CAMLreturn(Val_unit);
}
