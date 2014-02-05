#import "VKSdk.h"
#import <caml/mlvalues.h>

@interface LightVkDelegate : NSObject <VKSdkDelegate>
{
	value success;
	value fail;
}

- (id)initWithSuccess:(value)s andFail:(value)f;

@end