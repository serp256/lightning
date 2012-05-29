
#ifndef __LIGHT_COMMON_H__
#define __LIGHT_COMMON_H__

#include <caml/callback.h>
#include <caml/fail.h>

#define ERROR(fmt,args...) fprintf(stderr,fmt, ## args)


#define DEBUGMSG(fmt,args...) (fprintf(stderr,"[DEBUG(%s:%d)] ",__FILE__,__LINE__),fprintf(stderr,fmt, ## args),putc('\n',stderr))

#ifdef LDEBUG
    #define PRINT_DEBUG(fmt,args...) DEBUGMSG(fmt,## args) 
#else
    #define PRINT_DEBUG(fmt,args...)
#endif

/*
#ifndef RELEASE
#define checkGLErrors(fmt,args...) \
{ GLenum error = glGetError(); \
	int is_error = 0;\
	while (error != GL_NO_ERROR) { \
		printf("(%s:%d) gl error: %X [",__FILE__,__LINE__,error); \
		printf(fmt,## args);\
		printf("]\n"); \
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


