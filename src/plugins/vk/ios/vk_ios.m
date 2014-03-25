#import "LightAppDelegate.h"
#import "LightVkDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"
#import "VKApiConst.h"

static LightVkDelegate* delegate; //delegate declared as static, cause VKSdk class stores delegate as weak propety and auto ref counting clean given delegate, if it declared as local variable in ml_vk_authorize
static int authorized = 0;

value ml_vk_authorize(value vappid, value vpermissions, value vfail, value vsuccess) {
	if (authorized) return Val_unit;
	authorized = 1;

	CAMLparam4(vappid, vpermissions, vfail, vsuccess);

    [[NSNotificationCenter defaultCenter] addObserverForName:APP_OPENURL_SOURCEAPP object:nil queue:nil usingBlock:^(NSNotification* notif) {
    	NSDictionary* data = [notif userInfo];
    	NSURL* url = [data objectForKey:APP_URL_DATA];
    	NSString* fromApp = [data objectForKey:APP_SOURCEAPP_DATA];

    	[VKSdk processOpenURL:url fromApplication:fromApp];
    }];	

	delegate = [[LightVkDelegate alloc] initWithSuccess:vsuccess andFail:vfail];
	[VKSdk initializeWithDelegate:delegate andAppId:[NSString stringWithUTF8String:String_val(vappid)]];

	value perms = vpermissions;
	NSMutableArray* mpermissions = [NSMutableArray arrayWithCapacity:0];

	while(Is_block(perms)) {
		[mpermissions addObject:[NSString stringWithUTF8String:String_val(Field(perms, 0))]];
		perms = Field(perms, 1);
	}

	[VKSdk authorize:mpermissions];

	CAMLreturn(Val_unit);
}

value ml_vk_friends(value vfail, value vsuccess, value vt) {
	CAMLparam2(vfail, vsuccess);

	value success;
	value fail;

	REG_CALLBACK(vsuccess, success);
	REG_OPT_CALLBACK(vsuccess, fail);

	static value* create_friend = NULL;
	if (!create_friend) create_friend = caml_named_value("create_friend");

	VKRequest* req = [[VKApi friends] get:[NSDictionary dictionaryWithObject:@"sex" forKey:VK_API_FIELDS]];
	[req executeWithResultBlock:
			^(VKResponse* response) {
				CAMLparam0();
				CAMLlocal2(vitems, head);
				int err = 0;

				do {
					if (![response.json isKindOfClass:[NSDictionary class]]) {
						err = 1;
						break;
					}

					NSArray* mitems = [response.json objectForKey:@"items"];

					if (mitems == nil) {
						err = 1;
						break;
					}

					vitems = Val_int(0);

					for (id item in mitems) {
						NSDictionary* mitem = item;

						NSNumber* mid = [mitem objectForKey:@"id"];
						NSString* mfname = [mitem objectForKey:@"first_name"];
						NSString* mlname = [mitem objectForKey:@"last_name"];
						NSNumber* mgender = [mitem objectForKey:@"sex"];

						if (!(mid && mfname && mlname && mgender)) {
							err = 1;
							break;
						}

						NSString* mname = [NSString stringWithFormat:@"%@ %@", mlname, mfname];
						
						head = caml_alloc_tuple(2);
						Store_field(head, 0, caml_callback3(*create_friend, caml_copy_string([[mid stringValue] UTF8String]), caml_copy_string([mname UTF8String]), Val_int([mgender intValue])));
						Store_field(head, 1, vitems);

						vitems = head;
					}
				} while(NO);

				if (!err) {
					RUN_CALLBACK(success, vitems)
				} else {
					RUN_CALLBACK(fail, caml_copy_string("wrong format of response on friends request"));
				}

				CAMLreturn0;
			}
		errorBlock:
			^(NSError* error) {
				RUN_CALLBACK(fail, caml_copy_string([[error localizedDescription] UTF8String]));
			}
	];

	CAMLreturn(Val_unit);
}
