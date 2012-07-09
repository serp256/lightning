#include "light_common.h"
#include <caml/mlvalues.h>

#define DEBUG(str) __android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",str)
#define DEBUGF(fmt,args...)  __android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING",fmt, ## args)

typedef struct {
	int fd;
	int64_t length;
} resource;

int getResourceFd(const char *path, resource *res);

value ml_alsoundLoad(value path);
value ml_alsoundPlay(value soundId, value vol, value loop);
void ml_alsoundPause(value streamId);
void ml_alsoundStop(value streamId);
void ml_alsoundSetVolume(value streamId, value vol);
void ml_alsoundSetLoop(value streamId, value loop);
void ml_paymentsTest();
void ml_openURL(value url);
