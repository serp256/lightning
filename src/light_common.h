
#ifndef __LIGHT_COMMON_H__
#define __LIGHT_COMMON_H__
#define checkGLErrors(msg) check_gl_errors(__FILE__,__LINE__,msg)
void check_gl_errors(char*,int,char*);
#endif
