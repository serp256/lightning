#import "Odnoklassniki.h"
#import "OKSession.h"
#import <caml/mlvalues.h>

 @interface LightOkDelegate : NSObject <OKSessionDelegate>
{
	value *success;
	value *fail;
}
- (id)init;
- (void)authorizeWithSuccess:(value)s andFail:(value)f;
@end
