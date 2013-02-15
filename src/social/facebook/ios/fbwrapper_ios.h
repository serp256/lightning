#import "Facebook.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>

@interface LightFBDialogDelegate : NSObject <FBDialogDelegate>
{
	value* _successCallbackRequest;
	value* _failCallbackRequest;
	value* _successCallbackGraphApi;
	value* _failCallbackGraphApi;
	value usersIds;
}

- (id)initWithSuccessCallbackRequest:(value*)successCallback andFailCallback:(value*)failCallback;
- (void)freeCallbacksRequests;
@end

void ml_fbInit(value appid);

void ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken(value connect);
void ml_fbApprequest(value connect, value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value connect, value path, value params, value successCallback, value failCallback);
