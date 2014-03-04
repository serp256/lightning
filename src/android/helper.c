#include "activity.h"

static JNIEnv* env;
static jclass helper_cls;

void helper_init() {
/*    (*VM)->AttachCurrentThread(VM, &env, NULL);

    jclass cls = (*env)->GetObjectClass(env, ACTIVITY->clazz);
    jmethodID mid = (*env)->GetMethodID(env, cls, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject cls_ldr = (*env)->CallObjectMethod(env, ACTIVITY->clazz, mid);
    cls = (*env)->GetObjectClass(env, cls_ldr);
    mid = (*env)->GetMethodID(env, cls, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
    jstring jcls_name = (*env)->NewStringUTF(env, "ru.redspell.lightning.LightNativeActivityHelper");
    helper_cls = (*env)->CallObjectMethod(env, cls_ldr, mid, jcls_name);
    (*env)->DeleteLocalRef(env, jcls_name);
*/}

char* get_locale() {
	return "en";	
}