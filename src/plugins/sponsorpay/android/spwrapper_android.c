#include "plugin_common.h"

static jclass sponsorpayCls = NULL;

#define GET_CLS GET_PLUGIN_CLASS(sponsorpayCls,ru/redspell/lightning/plugins/LightSponsorpay);

void ml_sponsorPay_start(value v_appId, value v_userId, value v_securityToken) {
	GET_ENV;
	GET_CLS;

	jstring j_appId = (*env)->NewStringUTF(env, String_val(v_appId));
	jstring j_userId = (*env)->NewStringUTF(env, String_val(v_userId));
	jstring j_securityToken = (*env)->NewStringUTF(env, String_val(v_securityToken));

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "init", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid, j_appId, j_userId, j_securityToken);

	(*env)->DeleteLocalRef(env, j_appId);
	(*env)->DeleteLocalRef(env, j_userId);
	(*env)->DeleteLocalRef(env, j_securityToken);
}

void ml_sponsorPay_showOffers() {
	GET_ENV;
	GET_CLS;

	jmethodID mid = (*env)->GetStaticMethodID(env, sponsorpayCls, "showOfferts", "()V");
	(*env)->CallStaticVoidMethod(env, sponsorpayCls, mid);
}

/*#include "mlwrapper_android.h"

static int started = 0;

void ml_sponsorPay_start(value appId, value userId, value securityToken) {
	if (!started) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
		jstring jAppId = (*env)->NewStringUTF(env,String_val(appId));
		jstring jUserId = NULL;
		if (userId != Val_none) {
			jUserId = (*env)->NewStringUTF(env,String_val(Field(userId,0)));
		};
		jstring jSecurityToken = NULL;
		if (securityToken != Val_none) {
			jSecurityToken = (*env)->NewStringUTF(env,String_val(Field(securityToken,0)));
		};
		jobject jAppContext = jApplicationContext(env);
		jclass jSponsorPayCls = (*env)->FindClass(env,"com/sponsorpay/sdk/android/SponsorPay");
		jmethodID jStartM = (*env)->GetStaticMethodID(env,jSponsorPayCls,"start","(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Landroid/content/Context;)Ljava/lang/String;");
		jstring res = (*env)->CallStaticObjectMethod(env,jSponsorPayCls,jStartM,jAppId,jUserId,jSecurityToken,jAppContext);
		(*env)->DeleteLocalRef(env,jAppId);
		if (jUserId) (*env)->DeleteLocalRef(env,jUserId);
		if (jSecurityToken) (*env)->DeleteLocalRef(env,jSecurityToken);
		(*env)->DeleteLocalRef(env,jAppContext);
		(*env)->DeleteLocalRef(env,jSponsorPayCls);
		(*env)->DeleteLocalRef(env,res);
		started = 1;
	}
}


void ml_sponsorPay_showOffers() {
	if (!started) caml_failwith("sponsor pay not started");
	//SponsorPayPublisher.getIntentForOfferWallActivity(context, shouldStayOpen),
	PRINT_DEBUG("sponsor pay show offers");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jclass jSponsorPayPublisherCls = (*env)->FindClass(env,"com/sponsorpay/sdk/android/publisher/SponsorPayPublisher");
	//Context context, Boolean shouldStayOpen
	jmethodID getIntentM = (*env)->GetStaticMethodID(env,jSponsorPayPublisherCls,"getIntentForOfferWallActivity","(Landroid/content/Context;Ljava/lang/Boolean;)Landroid/content/Intent;");
	PRINT_DEBUG("CALL STATIC METHOD: %d for class %d",getIntentM,jSponsorPayPublisherCls);
	jobject jIntent = (*env)->CallStaticObjectMethod(env,jSponsorPayPublisherCls,getIntentM,jActivity,JNI_FALSE);
	//SponsorPayPublisher.DEFAULT_OFFERWALL_REQUEST_CODE = 0xFF
	jclass jLightActivityCls = (*env)->GetObjectClass(env,jActivity);
	jmethodID startActivityM = (*env)->GetMethodID(env,jLightActivityCls,"startActivityForResult","(Landroid/content/Intent;I)V");
	PRINT_DEBUG("startActivityForResult method: %d",startActivityM);
	//startActivityForResult(offerWallIntent, SponsorPayPublisher.DEFAULT_OFFERWALL_REQUEST_CODE);
	(*env)->CallVoidMethod(env,jActivity,startActivityM,jIntent,0xFF);
	(*env)->DeleteLocalRef(env,jSponsorPayPublisherCls);
	(*env)->DeleteLocalRef(env,jIntent);
	(*env)->DeleteLocalRef(env,jLightActivityCls);
}
*/