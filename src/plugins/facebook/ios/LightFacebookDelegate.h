
#import "LightAppDelegate.h"
#import "LightViewController.h"
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

@interface LightFacebookDelegate : NSObject <FBSDKSharingDelegate> { 
	value *success;
	value *fail;
}

- (id)initWithSuccess:(value)s andFail:(value)f;
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results;
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error;
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer;
@end
