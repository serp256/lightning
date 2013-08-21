#import "FacebookSDK.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>

@interface LightFBDialogDelegate : NSObject <FBWebDialogDelegate>
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
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback);
value ml_fb_share_pic_using_native_app(value v_fname, value v_text);
value ml_fb_share_pic(value v_success, value v_fail, value v_fname, value v_text);