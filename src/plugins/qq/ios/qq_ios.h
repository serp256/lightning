
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
//#import <MediaPlayer/MediaPlayer.h>
//#import <MobileCoreServices/MobileCoreServices.h>
//#import <CommonCrypto/CommonDigest.h>
//#import <TencentOpenAPI/TencentApiInterface.h>
//#import <TencentOpenAPI/TencentMessageObject.h>


#import "mlwrapper_ios.h"

value ml_qq_init (value vappid, value vuid, value vtoken, value vexpires);
value ml_qq_authorize(value vfail, value vsuccess, value vforce);
value ml_qq_token(value unit);
value ml_qq_uid(value unit);
value ml_qq_logout (value unit);
value ml_qq_friends(value vfail, value vsuccess);
