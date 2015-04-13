#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/fail.h>

value ml_fbInit(value appid);

value ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken(value connect);
value ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
value ml_fbGraphrequest(value path, value params, value successCallback, value failCallback, value http_method);
value ml_fb_share_pic_using_native_app(value v_fname, value v_text);
value ml_fb_share_pic(value v_success, value v_fail, value v_fname, value v_text);

static const int EXTRA_PERMS_NOT_REQUESTED = 0;
static const int READ_PERMS_REQUESTED = 1;
static const int PUBLISH_PERMS_REQUESTED = 2;
