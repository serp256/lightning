#include "mlwrapper_android.h"

#define GET_LIGHT_NOTIFICATIONS 														\
	JNIEnv *env;																		\
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);						\
	if (!notifCls) {																	\
		jclass cls = (*env)->FindClass(env,"ru/redspell/lightning/LightNotifications");	\
		notifCls = (*env)->NewGlobalRef(env, cls);										\
		(*env)->DeleteLocalRef(env, cls);												\
	}																					\

static jclass notifCls = 0;

value ml_lnSchedule(value notifId, value fireDate, value message) {
	GET_LIGHT_NOTIFICATIONS;

	jstring jnotifId = (*env)->NewStringUTF(env, String_val(notifId));
	jdouble jfireDate = (jdouble)Double_val(fireDate) * 1000;
	jstring jmessage = (*env)->NewStringUTF(env, String_val(message));

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, notifCls, "scheduleNotification", "(Ljava/lang/String;DLjava/lang/String;)V");

	(*env)->CallStaticVoidMethod(env, notifCls, mid, jnotifId, jfireDate, jmessage);

	(*env)->DeleteLocalRef(env, jnotifId);
	(*env)->DeleteLocalRef(env, jmessage);

	return Val_true;
}

value ml_lnCancel(value notifId) {
	GET_LIGHT_NOTIFICATIONS;

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, notifCls, "cancelNotification", "(Ljava/lang/String;)V");

	jstring jnotifId = (*env)->NewStringUTF(env, String_val(notifId));
	(*env)->CallStaticVoidMethod(env, notifCls, mid, jnotifId);
	(*env)->DeleteLocalRef(env, jnotifId);

	return Val_unit;
}
