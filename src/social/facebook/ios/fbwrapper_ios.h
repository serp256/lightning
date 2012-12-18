#import "Facebook.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>
#import "fbwrapper.h"

@interface LightFBDialogDelegate : NSObject <FBDialogDelegate>
{
	value* _successCallback;
	value* _failCallback;
	value usersIds;
}

- (id)initWithSuccessCallback:(value*)successCallback andFailCallback:(value*)failCallback;
- (void)freeCallbacks;
@end

void ml_fbInit(value appid);

void ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken(value connect);
void ml_fbApprequest(value connect, value title, value message, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value connect, value path, value params, value successCallback, value failCallback);