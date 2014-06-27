#import "light_common.h"

float deviceScaleFactor();
int getResourceFd(const char *path, resource *res);

#define IOS6 ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)