#import "LightAppDelegate.h"
#import "LightVkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"
#import "VKApiConst.h"

static LightVkDelegate* delegate; //delegate declared as static, cause VKSdk class stores delegate as weak propety and auto ref counting clean given delegate, if it declared as local variable in ml_vk_authorize
int authorized = 0;

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess, value vforce) {
	NSLog(@"ml_vk_authorize call");
	if (authorized && vforce == Val_false) {
		value *success = &vsuccess;
		NSLog(@"ml_vk_authorize 1 success");
		RUN_CALLBACK(success, Val_unit);

		return Val_unit;
	}

	CAMLparam4(vappid, vpermissions, vfail, vsuccess);

	NSLog(@"1");
	[[NSNotificationCenter defaultCenter] addObserverForName:APP_OPENURL_SOURCEAPP object:nil queue:nil usingBlock:^(NSNotification* notif) {
		NSDictionary* data = [notif userInfo];
		NSURL* url = [data objectForKey:APP_URL_DATA];
		NSString* fromApp = [data objectForKey:APP_SOURCEAPP_DATA];

		[VKSdk processOpenURL:url fromApplication:fromApp];
	}];

	NSLog(@"2");
	delegate = [[LightVkDelegate alloc] initWithSuccess:vsuccess andFail:vfail andAuthFlag:(&authorized)];
	[VKSdk initializeWithDelegate:delegate andAppId:[NSString stringWithUTF8String:String_val(vappid)]];

	NSLog(@"3");
	VKAccessToken *token = [VKAccessToken tokenFromDefaults:@"lightning_nativevk_token"];

	if (token == nil || token.isExpired == YES || vforce == Val_true) {
		NSLog(@"4");
		value perms = vpermissions;
		NSMutableArray* mpermissions = [NSMutableArray arrayWithCapacity:0];

		while(Is_block(perms)) {
			[mpermissions addObject:[NSString stringWithUTF8String:String_val(Field(perms, 0))]];
			perms = Field(perms, 1);
		}

		NSLog(@"5");
		[VKSdk authorize:mpermissions];
	} else {
		NSLog(@"6");
		[VKSdk setAccessToken:token];
	}

	CAMLreturn(Val_unit);
}

value ml_vk_authorize_byte(value *argv, int n) {
	return ml_vk_authorize(argv[0], argv[1], argv[2], argv[3], argv[4]);
}

value ml_vk_token(value t) {
	return caml_copy_string([[VKSdk getAccessToken].accessToken UTF8String]);
}

value ml_vk_uid(value t) {
	return caml_copy_string([[VKSdk getAccessToken].userId UTF8String]);
}

static value *create_user = NULL;

void vk_users_request(VKRequest *req, value vfail, value vsuccess) {
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

value ml_vk_friends(value vfail, value vsuccess, value vt) {
	vk_users_request([[VKApi friends] get:[NSDictionary dictionaryWithObject:@"sex,photo_max,last_seen" forKey:VK_API_FIELDS]], vfail, vsuccess);
	return Val_unit;
}

value ml_vk_users(value vfail, value vsuccess, value vids) {
	NSString *mids = [NSString stringWithUTF8String:String_val(vids)];
	vk_users_request([[VKApi users] get:[NSDictionary dictionaryWithObjectsAndKeys:@"sex,photo_max,last_seen", VK_API_FIELDS, mids, VK_API_USER_IDS, nil ]], vfail, vsuccess);
	return Val_unit;
}
