#import "VKSdk.h"
#import <caml/mlvalues.h>

@interface LightVkDelegate : NSObject <VKSdkDelegate>
{
	value success;
	value fail;
	int *authorized;
}

- (id)initWithSuccess:(value)s andFail:(value)f andAuthFlag:(int*)fl;

@end
