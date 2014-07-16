#include "lightning_android.h"
#include "engine.h"

#define GET_LIGHT_NOTIFICATIONS if (!cls) cls = engine_find_class("ru/redspell/lightning/notifications/Notifications");

static jclass cls = 0;

value ml_lnSchedule(value notifId, value fireDate, value message) {
	GET_LIGHT_NOTIFICATIONS;

	jstring jnotifId = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(notifId));
	jdouble jfireDate = (jdouble)Double_val(fireDate) * 1000;
	jstring jmessage = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(message));

	static jmethodID mid;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "scheduleNotification", "(Ljava/lang/String;DLjava/lang/String;)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jnotifId, jfireDate, jmessage);

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jnotifId);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jmessage);

	return Val_true;
}

value ml_lnCancel(value notifId) {
	GET_LIGHT_NOTIFICATIONS;

	static jmethodID mid;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "cancelNotification", "(Ljava/lang/String;)V");

	jstring jnotifId = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(notifId));
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jnotifId);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jnotifId);

	return Val_unit;
}

value ml_lnCancelAll(value p) {
	GET_LIGHT_NOTIFICATIONS;

	static jmethodID mid;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "cancelAll", "()V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid);

	return Val_unit;
}

value ml_lnClearAll(value p) {
	GET_LIGHT_NOTIFICATIONS;

	static jmethodID mid;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "clearAll", "()V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid);

	return Val_unit;
}
