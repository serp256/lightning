#include "light_common.h"
#include <caml/mlvalues.h>

#define DEBUG(str) __android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",str)
#define DEBUGF(fmt,args...)  __android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING",fmt, ## args)

typedef struct {
	int fd;
	int64_t length;
} resource;

int getResourceFd(const char *path, resource *res);
