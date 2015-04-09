#include "plugin_common.h"

void ml_fbInit(value appId);

void ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken();
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback, value http_method);
