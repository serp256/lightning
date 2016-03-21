#import "LightAppDelegate.h"
#import "LightQQDelegate.h"
#import "LightViewController.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
//#import <UIKit/UIDevice.h>
#import "common_ios.h"

 #import <TencentOAuth.h>
 #import <QQApiInterfaceObject.h>
 #import <QQApiInterface.h>
//#import <MediaPlayer/MediaPlayer.h>
//#import <MobileCoreServices/MobileCoreServices.h>
//#import <CommonCrypto/CommonDigest.h>
//#import <TencentOpenAPI/TencentApiInterface.h>
//#import <TencentOpenAPI/TencentMessageObject.h>


#import "mlwrapper_ios.h"

static TencentOAuth *_tencentOAuth;
static LightQQDelegate *delegate;

value ml_qq_init (value vappid, value vuid, value vtoken, value vexpires) {
	CAMLparam4(vappid, vuid, vtoken, vexpires);

	PRINT_DEBUG ("ml_qq_init");



	NSNotificationCenter* notifCntr = [NSNotificationCenter defaultCenter];
	[notifCntr addObserverForName:APP_OPENURL_SOURCEAPP object:nil queue:nil usingBlock:^(NSNotification* notif) {
			NSLog(@"handling application open url source");
			NSDictionary* data = [notif userInfo];
			NSURL* url = [data objectForKey:APP_URL_DATA];

			[TencentOAuth HandleOpenURL:url];
			//[[FBSDKApplicationDelegate sharedInstance] application:app openURL:url sourceApplication:sourceApp annotation:nil];
	}];
	[notifCntr addObserverForName:APP_OPENURL object:nil queue:nil usingBlock:^(NSNotification* notif) {
			NSLog(@"handling application open url ");
			NSDictionary* data = [notif userInfo];
			NSURL* url = [data objectForKey:APP_URL_DATA];

			[TencentOAuth HandleOpenURL:url];
			//[[FBSDKApplicationDelegate sharedInstance] application:app openURL:url sourceApplication:sourceApp annotation:nil];
	}];

	NSString* appId = [NSString stringWithCString:String_val(vappid) encoding:NSUTF8StringEncoding];
	NSLog(@"app id %@", appId);

	if (!_tencentOAuth) {

		delegate = [[LightQQDelegate alloc] init];
		_tencentOAuth = [[TencentOAuth alloc] initWithAppId:appId andDelegate:delegate];
	}

	if (Is_block(vtoken)) {
		NSString* accessToken = [NSString stringWithCString:String_val(Field(vtoken,0)) encoding:NSUTF8StringEncoding];
		NSLog(@" token %@", accessToken);
		[_tencentOAuth setAccessToken:accessToken];
	}
	if (Is_block(vuid)) {
		NSString* uid = [NSString stringWithCString:String_val(Field(vuid,0)) encoding:NSUTF8StringEncoding];
		NSLog(@" uid %@", uid);
		[_tencentOAuth setOpenId:uid];
	}
	if (Is_block(vexpires)) {
		NSString* expires= [NSString stringWithCString:String_val(Field(vexpires,0)) encoding:NSUTF8StringEncoding];
		NSDate* expirationDate = [[NSDate alloc] initWithTimeIntervalSince1970:[expires intValue]];
		NSLog(@"expires %s = %d", expires, [expires intValue]);
		[_tencentOAuth setExpirationDate:expirationDate] ;
	}
	NSLog(@"isSessionValid %@", [_tencentOAuth isSessionValid] ? @"yes":@"no");
	CAMLreturn(Val_unit);
}

value ml_qq_authorize(value vfail, value vsuccess, value vforce) {
	CAMLparam3(vfail, vsuccess, vforce);

	PRINT_DEBUG ("ml_qq_authorize");
		[delegate initWithSuccess:vsuccess andFail:vfail];

	PRINT_DEBUG ("ml_qq_authorize_1");
	if (!_tencentOAuth) {
			value *fail;
			REG_CALLBACK(vfail, fail);
			RUN_CALLBACK(fail, "Need call init first");
			FREE_CALLBACK(fail);
	}
	else {
		if (vforce == Val_true) {
			PRINT_DEBUG ("qq: force logout");
			[_tencentOAuth logout: nil]; 
		}
		if (![_tencentOAuth isSessionValid]) {
			NSArray* permissions = [NSArray arrayWithObjects:
				kOPEN_PERMISSION_GET_USER_INFO,
				kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
				kOPEN_PERMISSION_ADD_SHARE,
				nil];
			[_tencentOAuth authorize:permissions inSafari:NO];
			}
		else {
			PRINT_DEBUG ("alreasy auth");
			value *success;
			REG_CALLBACK(vsuccess, success);
			RUN_CALLBACK(success, Val_unit);
			FREE_CALLBACK(success);
		}
	}

	CAMLreturn(Val_unit);
}

value ml_qq_uid(value unit) {
	if(_tencentOAuth) {
		if ([_tencentOAuth openId]) {
			return caml_copy_string([[_tencentOAuth openId] cStringUsingEncoding:NSASCIIStringEncoding]);
		}
		return (caml_copy_string(""));
	}
	return (caml_copy_string(""));
}

value ml_qq_expires(value unit) {
	if(_tencentOAuth) {
		if ([_tencentOAuth expirationDate]) {
			int seconds = [[_tencentOAuth expirationDate] timeIntervalSince1970];
			NSString* expires = [@(seconds) stringValue];
			NSLog(@"expires %@", expires);
			return caml_copy_string([expires cStringUsingEncoding:NSASCIIStringEncoding]);
		}
	}
	return (caml_copy_string(""));
}

value ml_qq_token(value unit) {
	if(_tencentOAuth) {
		if ([_tencentOAuth accessToken]) {
			return caml_copy_string([[_tencentOAuth accessToken] cStringUsingEncoding:NSASCIIStringEncoding]);
		}
		return (caml_copy_string(""));
	}
	return (caml_copy_string(""));
}

value ml_qq_logout (value unit) {
	if (_tencentOAuth) {
		[_tencentOAuth logout: nil]; 
  }
	return (Val_unit);
}


value ml_qq_share (value vtitle, value vsummary, value vurl, value vimageUrl) {
	CAMLparam4(vtitle, vsummary, vurl, vimageUrl);

	/*
		TCAddShareDic *params = [TCAddShareDic dictionary];

		params.paramTitle   = @"test";
		params.paramSummary = @"test";
	//	params.paramTitle   = [NSString stringWithCString:String_val(vtitle) encoding:NSUTF8StringEncoding];
	//	params.paramSummary = [NSString stringWithCString:String_val(vsummary) encoding:NSUTF8StringEncoding];
		params.paramImages  = [NSString stringWithCString:String_val(vimageUrl) encoding:NSUTF8StringEncoding];
		params.paramUrl     = [NSString stringWithCString:String_val(vurl) encoding:NSUTF8StringEncoding];
		params.paramComment= @"test";

		BOOL result =	[_tencentOAuth addShareWithParams:params];
		NSLog(result? @"Yes" : @"No");

	*/
	NSLog(@"share");
	/*
		NSString *utf8String = @"http://www.163.com";
		NSString *title = @"title";
		NSString *description = @"descr";
		NSString *previewImageUrl = @"http://cdni.wired.co.uk/620x413/k_n/NewsForecast%20copy_620x413.jpg";
		QQApiNewsObject *newsObj = [QQApiNewsObject
			objectWithURL:[NSURL URLWithString:utf8String]
							title:title
				description:description
		previewImageURL:[NSURL URLWithString:previewImageUrl]];
		SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
		//将内容分享到qq
		QQApiSendResultCode sent = [QQApiInterface sendReq:req];
		////将内容分享到qzone
		//QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
		*/

	NSString *url = [NSString stringWithCString:String_val(vurl) encoding:NSUTF8StringEncoding];
	NSString *title =[NSString stringWithCString:String_val(vtitle) encoding:NSUTF8StringEncoding];
	NSString *description = [NSString stringWithCString:String_val(vsummary) encoding:NSUTF8StringEncoding];
	NSString *previewImageUrl = [NSString stringWithCString:String_val(vimageUrl) encoding:NSUTF8StringEncoding];
	QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:[NSURL URLWithString:url] title:title description:description previewImageURL:[NSURL URLWithString:previewImageUrl]]; 
	
	//[newsObj setCflag:kQQAPICtrlFlagQZoneShareOnStart];
	//[newsObj setCflag: kQQAPICtrlFlagQZoneShareForbid];
	//[newsObj setTitle:title ? : @""];

	[newsObj setCflag:kQQAPICtrlFlagQQShare];
	SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];

	QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];

	NSLog(@"%d", sent);

	/*
	 NSURL *previewURL = [NSURL URLWithString:@"http://baidu.com"];
	    NSString *path = [[NSBundle mainBundle] bundlePath];
			    NSString *name = [NSString stringWithFormat:@"1.png"];
					    NSString *finalPath = [path stringByAppendingPathComponent:name];
							    NSData *previeImgData = [NSData dataWithContentsOfFile:finalPath];
									    QQApiNewsObject *imgObj = [QQApiNewsObject objectWithURL:previewURL title:@"分享内容的title" description:@"本宝宝是内容的描述" previewImageData:previeImgData];

											[imgObj setCflag:kQQAPICtrlFlagQZoneShareOnStart];
											//[imgObj setCflag:kQQAPICtrlFlagQQShare];
											   
											    
											    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imgObj];
													    QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
															NSLog(@"%d", sent);
															*/
	CAMLreturn(Val_unit);
}



