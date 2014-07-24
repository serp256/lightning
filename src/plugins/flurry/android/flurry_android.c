#include "plugin_common.h"

void ml_flurryStartSession(value vappid) {
	static int started = 0;
	if (started) return;

	jclass cls = engine_find_class("com/flurry/android/FlurryAgent");
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "onStartSession", "(Landroid/content/Context;Ljava/lang/String;)V");

	jstring jappid = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vappid));
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, JAVA_ACTIVITY, jappid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jappid);
	started = 1;
}
