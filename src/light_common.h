
#ifndef __LIGHT_COMMON_H__
#define __LIGHT_COMMON_H__

#ifdef ANDROID
#include <android/log.h>
#endif

#include <caml/callback.h>
#include <caml/fail.h>

#ifdef ANDROID
#define PRINT_ERROR(msg) __android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",msg)
#else
#define PRINT_ERROR(msg) (fputs(msg,stderr),fputc('\n',stderr))
#endif


#ifdef ANDROID
#define ERROR(fmt,args...) __android_log_print(ANDROID_LOG_ERROR,"LIGHTNING",fmt, ## args)
#else
#define ERROR(fmt,args...) (fprintf(stderr,fmt, ## args),fputc('\n',stderr))
#endif


#define DEBUGMSG(fmt,args...) (fprintf(stderr,"[DEBUG(%s:%d)] ",__FILE__,__LINE__),fprintf(stderr,fmt, ## args),putc('\n',stderr))

#ifdef LDEBUG
#ifdef ANDROID
#define PRINT_DEBUG(fmt,args...)  __android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING",fmt, ## args)
#else 
#define PRINT_DEBUG(fmt,args...) DEBUGMSG(fmt,## args) 
#endif
#else
#define PRINT_DEBUG(fmt,args...)
#endif

/*
#ifndef RELEASE
#define checkGLErrors(fmt,args...) \
{ GLenum error = glGetError(); \
	int is_error = 0; char buf[512]; int pos = 0; \
	while (error != GL_NO_ERROR) { \
		pos = sprintf(buf,"(%s:%d) gl error: %X [",__FILE__,__LINE__,error); \
		pos += sprintf(buf + pos,fmt,## args);\
		sprintf(buf + pos, "]\n"); \
		PRINT_ERROR(buf); \
		error = glGetError(); \
		is_error = 1; \
	}; \
	if (is_error) exit(1); \
}

#else
#define checkGLErrors(fmt,args...)
#endif
*/

#ifndef RELEASE
#define checkGLErrors(fmt,args...) \
{ GLenum error = glGetError(); \
	int is_error = 0; char buf[1024]; int pos = 0;\
	while (error != GL_NO_ERROR) { \
		pos = sprintf(buf + pos,"(%s:%d) gl error: %X [",__FILE__,__LINE__,error); \
    pos += sprintf(buf + pos,fmt,## args);\
    pos += sprintf(buf + pos, "]\n"); \
		error = glGetError(); \
		is_error = 1; \
	}; \
	if (is_error) caml_raise_with_string(*(caml_named_value("gl_error")),buf); \
}

#else
#define checkGLErrors(fmt,args...)
#endif

extern unsigned int MAX_GC_MEM;

#endif


