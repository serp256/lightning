#include "plugin_common.h"

static jclass cls = 0;

#define GET_CLS cls = engine_find_class("ru/redspell/lightning/plugins/LightTapjoy");

void ml_tapjoy_init(value vappID,value vsecretKey) {
	GET_CLS;

	jstring jappId, jsecKey;
	VAL_TO_JSTRING(vappID, jappId);
	VAL_TO_JSTRING(vsecretKey, jsecKey);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "init", "(Ljava/lang/String;Ljava/lang/String;)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jappId, jsecKey);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jappId);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jsecKey);
}

void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
	GET_CLS;

	jstring jcurrency;
	VAL_TO_JSTRING(currency, jcurrency);
	jboolean jshow_selector = Bool_val(show_selector);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "showOffersWithCurrencyID", "(Ljava/lang/String;Z)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jcurrency, jshow_selector);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jcurrency);
}

void ml_tapjoy_show_offers() {
	GET_CLS;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "showOffers", "()V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid);
}

void ml_tapjoy_set_user_id(value uid) {
	GET_CLS;

	jstring juid;
	VAL_TO_JSTRING(uid, juid);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "setUserID", "(Ljava/lang/String;)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, juid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, juid);
}

void ml_tapjoy_action_complete(value action) {
	GET_CLS;

	jstring jaction;
	VAL_TO_JSTRING(action, jaction);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "actionComplete", "(Ljava/lang/String;)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jaction);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jaction);
}
