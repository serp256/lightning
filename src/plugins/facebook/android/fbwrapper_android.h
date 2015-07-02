#include "plugin_common.h"

value ml_fbInit(value appId);

value ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken();
value ml_fbApprequest(value vtitle, value vmessage, value vrecipient, value vdata, value vsuccess, value vfail);
value ml_fbApprequest_byte(value * argv, int argn);
value ml_fbGraphrequest(value vpath, value vparams, value vsuccess, value vfail, value vhttp_method);
