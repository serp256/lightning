#import "LightAppDelegate.h"
#import "LightOkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"
#import "Odnoklassniki.h"

LightOkDelegate* delegate;
static Odnoklassniki* api; 
int authorized = 0;
int subscribed = 0;
NSString* uid; 

value ok_init (value vappid, value vappsecret, value vappkey) {
  NSLog(@"ok_init call");
	CAMLparam3 (vappid, vappsecret, vappkey);

	NSString* cappid     = [NSString stringWithUTF8String:String_val(vappid)];
	NSString* cappsecret = [NSString stringWithUTF8String:String_val(vappsecret)];
	NSString* cappkey    = [NSString stringWithUTF8String:String_val(vappkey)];

	NSLog(@"ok_subscribe %i", subscribed);
	if (!subscribed) {
		NSLog(@"ok_subscribe");
			subscribed = 1;
			[[NSNotificationCenter defaultCenter] addObserverForName:APP_OPENURL_SOURCEAPP object:nil queue:nil usingBlock:^(NSNotification* notif) {
				NSDictionary* data = [notif userInfo];
				NSURL* url = [data objectForKey:APP_URL_DATA];


				[OKSession.activeSession handleOpenURL:url];
			}];
		}

		NSLog(@"ok_create delegate");

	delegate = [[LightOkDelegate alloc] init];

	api = [[Odnoklassniki alloc] initWithAppId:cappid appSecret:cappsecret appKey:cappkey delegate:delegate];

  CAMLreturn(Val_unit);
}


void get_current_user (value* fail,  value* success) {
  NSLog(@"get current user call");
    OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"users.getCurrentUser" params:nil];
    [newRequest executeWithCompletionBlock:^(NSDictionary *data) {
			NSLog(@"iuser %@", data);
        if (![data isKindOfClass:[NSDictionary class]]) {
						RUN_CALLBACK(fail, caml_copy_string("fail when try to get currrent user"));
            return;
        }

				uid  = [data objectForKey:@"uid"];
				RUN_CALLBACK(success, Val_unit);
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
				RUN_CALLBACK(fail, caml_copy_string("fail when try to get currrent user"));
    }];
}

value ok_authorize (value vfail, value vsuccess) {
  NSLog(@"ok_authorize call");
	CAMLparam2 (vsuccess, vfail);

	[delegate authorizeWithSuccess:vsuccess andFail: vfail];

	if (api.isSessionValid) {
		NSLog(@"ok_Logged in");
		[api refreshToken];
	} else {
		NSLog (@"ok_not logged in");
		[api authorizeWithPermissions:@[@"VALUABLE ACCESS"]];
	}
  CAMLreturn(Val_unit);
}

static value *create_user = NULL;

void users_request(NSString* uids, value* fail,  value* success) {
	if (!create_user) create_user = caml_named_value("create_user");
    OKRequest *request = [Odnoklassniki requestWithMethodName:@"users.getInfo" params:@ {
            @"uids": uids,
            @"fields": @"uid,first_name,last_name,gender, online, last_online, pic190x190"
    }];

    [request executeWithCompletionBlock:^(NSArray *friendsInfo) {

			CAMLparam0();
			CAMLlocal2(vitems, head);
			int err = 0;

			do {
				if (friendsInfo== nil) {
					err = 1;
					break;
				}

				vitems = Val_int(0);

				for (id item in friendsInfo) {
					NSDictionary* mitem = item;

					NSLog(@"mitem %@", mitem);

					NSString* mid = [mitem objectForKey:@"uid"];
					NSString* mfname = [mitem objectForKey:@"first_name"];
					NSString* mlname = [mitem objectForKey:@"last_name"];
					NSString* mgender = [mitem objectForKey:@"gender"];
					NSString* mphoto = [mitem objectForKey:@"pic190x190"];
					NSString* online = [mitem objectForKey:@"online"];
					NSString* lastSeen = [mitem objectForKey:@"last_online"];
					double lastSeenTime = 0;

					if (lastSeen != nil) {
						NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
						[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
						NSDate *date = [formatter dateFromString:lastSeen];
						NSString *dateString = [formatter stringFromDate:[NSDate date]];

						lastSeenTime =[date timeIntervalSince1970];
					}

					if (!(mid && mfname && mlname && mgender)) {
						err = 1;
						break;
					}

					NSString* mname = [NSString stringWithFormat:@"%@ %@", mlname, mfname];

					head = caml_alloc_tuple(2);
					value args[6] = { caml_copy_string([mid UTF8String]), caml_copy_string([mname UTF8String]), Val_int( [mgender isEqualToString:@"female"] ? 1: [mgender isEqualToString:@"male"] ? 2: 0),
										caml_copy_string([mphoto UTF8String]), online != nil ? Val_true : Val_false, caml_copy_double(lastSeenTime)};
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

			FREE_CALLBACK(fail);
			FREE_CALLBACK(success);

			CAMLreturn0;

    } errorBlock:^(NSError *error) {
        NSLog(@"%@", [error localizedDescription]);
				RUN_CALLBACK(fail, caml_copy_string([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(fail);
				FREE_CALLBACK(success);
    }];
}

value ok_friends(value vfail, value vsuccess) {
	CAMLparam2(vfail, vsuccess);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"friends.get" params:nil];
	[newRequest executeWithCompletionBlock:^(NSArray *uids) {
			if (![uids isKindOfClass:[NSArray class]] || !uids.count) {
				NSLog(@"1");
				RUN_CALLBACK(success, Val_int(0))
			  FREE_CALLBACK(fail);
				FREE_CALLBACK(success);
				return;
			}

			NSLog(@"2");
			NSString* ids = uids.count >= 100 ? [[uids subarrayWithRange:NSMakeRange(0, 100)] componentsJoinedByString:@","]: [uids componentsJoinedByString:@","];
			NSLog(@"ids %@", ids);
			users_request(ids, fail, success);
	 } errorBlock:^(NSError *error) {
			NSLog(@"%@", error);
			RUN_CALLBACK(fail, caml_copy_string ([[error localizedDescription] UTF8String]));
			FREE_CALLBACK(fail);
			FREE_CALLBACK(success);
	 }
	];

  CAMLreturn(Val_unit);
}

value ok_users(value vfail, value vsuccess, value vids) {
	NSString *mids = [NSString stringWithUTF8String:String_val(vids)];
	NSLog(@"ids %@", mids);
	CAMLparam2(vfail, vsuccess);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	if ([mids length] == 0) {
		RUN_CALLBACK(success, Val_int(0))
		FREE_CALLBACK(fail);
		FREE_CALLBACK(success);
	}
	else 
	{
		users_request(mids, fail, success);
	}
	CAMLreturn(Val_unit);
}

value ok_token (value unit) {
	return(caml_copy_string([api.session.accessToken UTF8String]));
}

value ok_uid (value unit){
	return(caml_copy_string([uid UTF8String]));
}
