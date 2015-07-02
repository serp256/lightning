#import "mlwrapper_ios.h"
#import "LightFacebookDelegate.h"
#import <caml/memory.h>
#import <caml/alloc.h>
#import "LightViewController.h"

@implementation LightFacebookDelegate
- (id)initWithSuccess:(value)s andFail:(value)f {
	self = [super init];
	REG_OPT_CALLBACK(s, success);
	REG_OPT_CALLBACK(f, fail);
	return self;
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
		NSLog(@"success");
		RUN_CALLBACK(success, Val_unit);
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
	}
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
		NSLog(@"error %@", error);
		RUN_CALLBACK(fail, caml_copy_string ([[error localizedDescription] UTF8String]));
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
	}
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
		NSLog(@"cancel");
		RUN_CALLBACK(fail, caml_copy_string ("Sharing was cancelled"));
		FREE_CALLBACK(success);
		FREE_CALLBACK(fail);
	}

- (void)dealloc {
	NSLog(@"FB delegate dealloc");
	FREE_CALLBACK(success);
	FREE_CALLBACK(fail);
}
@end
