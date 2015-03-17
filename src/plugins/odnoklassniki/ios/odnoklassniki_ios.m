#import "LightAppDelegate.h"
#import "LightOkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"
#import "Odnoklassniki.h"

static LightOkDelegate* delegate; //delegate declared as static, cause VKSdk class stores delegate as weak propety and auto ref counting clean given delegate, if it declared as local variable in ml_vk_authorize
static Odnoklassniki* api; 
int authorized = 0;
int subscribed = 0;

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

value ok_authorize (value vfail, value vsuccess) {
  NSLog(@"ok_authorize call");
	CAMLparam2 (vsuccess, vfail);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);

	if (!api.session) {
		[api authorizeWithPermissions:@[@"VALUABLE ACCESS"]];
	}
	else {
		//if access_token is valid
		if (api.isSessionValid) {
			NSLog(@"Logged in");
			[delegate okDidLogin];
		} else {
			NSLog (@"Not logged in");
			[api refreshToken];
		}
	}
  CAMLreturn(Val_unit);
}

static value *create_user = NULL;

/*void vk_users_request(VKRequest *req, value vfail, value vsuccess) {
	CAMLparam2(vfail, vsuccess);

	value *fail, *success;
	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vfail, fail);
	if (!create_user) create_user = caml_named_value("create_user");

	[req executeWithResultBlock:
		^(VKResponse* response) {
			CAMLparam0();
			CAMLlocal2(vitems, head);
			int err = 0;

			NSLog(@"response %@", response);

			do {
				NSArray* mitems = nil;

				if ([response.json isKindOfClass:[NSDictionary class]]) {
					mitems = [response.json objectForKey:@"items"];
				}

				if ([response.json isKindOfClass:[NSArray class]]) {
					mitems = response.json;
				}

				if (mitems == nil) {
					err = 1;
					break;
				}

				vitems = Val_int(0);

				for (id item in mitems) {
					NSDictionary* mitem = item;

					NSLog(@"mitem %@", mitem);

					NSNumber* mid = [mitem objectForKey:@"id"];
					NSString* mfname = [mitem objectForKey:@"first_name"];
					NSString* mlname = [mitem objectForKey:@"last_name"];
					NSNumber* mgender = [mitem objectForKey:@"sex"];
					NSString* mphoto = [mitem objectForKey:@"photo_max"];
					NSNumber* online = [mitem objectForKey:@"online"];
					NSDictionary* lastSeen = [mitem objectForKey:@"last_seen"];
					double lastSeenTime = 0;

					if (lastSeen != nil) {
						NSNumber *_lastSeenTime = [lastSeen objectForKey:@"time"];
						lastSeenTime = [_lastSeenTime doubleValue];
					}

					if (!(mid && mfname && mlname && mgender)) {
						err = 1;
						break;
					}

					NSString* mname = [NSString stringWithFormat:@"%@ %@", mlname, mfname];

					head = caml_alloc_tuple(2);
					value args[6] = { caml_copy_string([[mid stringValue] UTF8String]), caml_copy_string([mname UTF8String]), Val_int([mgender intValue]),
										caml_copy_string([mphoto UTF8String]), [online intValue] == 1 ? Val_true : Val_false, caml_copy_double(lastSeenTime)};
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
		}

		errorBlock:
			^(NSError* error) {
				RUN_CALLBACK(fail, caml_copy_string([[error localizedDescription] UTF8String]));
				FREE_CALLBACK(fail);
				FREE_CALLBACK(success);
			}
	];

	CAMLreturn0;
}
*/
value vk_friends(value vfail, value vsuccess) {
	//vk_users_request([[VKApi friends] get:[NSDictionary dictionaryWithObject:@"sex,photo_max,last_seen,online" forKey:VK_API_FIELDS]], vfail, vsuccess);
	return Val_unit;
}

value ok_users(value vfail, value vsuccess, value vids) {

	//NSString *mids = [NSString stringWithUTF8String:String_val(vids)];
	//vk_users_request([[VKApi users] get:[NSDictionary dictionaryWithObjectsAndKeys:@"sex,photo_max,last_seen,online,online_mobile,online_app", VK_API_FIELDS, mids, VK_API_USER_IDS, nil ]], vfail, vsuccess);
	return Val_unit;
}
