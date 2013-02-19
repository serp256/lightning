#include "mlwrapper_android.h"
// #include "fbwrapper.h"

void ml_fbInit(value appId);

void ml_fbConnect();
value ml_fbLoggedIn();

value ml_fbAccessToken(value connect);
void ml_fbApprequest(value title, value message, value recipient, value data, value successCallback, value failCallback);
void ml_fbApprequest_byte(value * argv, int argn);
void ml_fbGraphrequest(value path, value params, value successCallback, value failCallback);
