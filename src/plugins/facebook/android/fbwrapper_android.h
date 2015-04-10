#include "plugin_common.h"

value ml_fbInit(value appId);

value ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken();
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
value ml_fbGraphrequest(value vpath, value vparams, value vsuccess, value vfail, value vhttp_method);
