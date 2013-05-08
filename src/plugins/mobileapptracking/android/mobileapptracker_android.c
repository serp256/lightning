
#include "mlwrapper_android.h"


static jclass mobileTrackerCls = NULL;
static jobject mobileTracker = NULL;


void ml_MATinit(value advertiser_id, value conversion_key, value site_id, value unit) {
	PRINT_DEBUG("INIT MAT");
	if (!mobileTracker) {
		PRINT_DEBUG("INIT MAT REALLY");
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
		PRINT_DEBUG("find class");
		jclass cls = (*env)->FindClass(env, "com/mobileapptracker/MobileAppTracker");
		PRINT_DEBUG("get constructor: %d",cls);
		jmethodID constrId = (*env)->GetMethodID(env, cls, "<init>", "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V");
		PRINT_DEBUG("constrId: %d",constrId);
		jstring jadv = (*env)->NewStringUTF(env, String_val(advertiser_id));
		jstring jconv = (*env)->NewStringUTF(env, String_val(conversion_key));
		jobject mt = (*env)->NewObject(env,cls,constrId,jActivity,jadv,jconv);
		mobileTrackerCls = (*env)->NewGlobalRef(env,cls);
		mobileTracker = (*env)->NewGlobalRef(env,mt);
		(*env)->DeleteLocalRef(env,jadv);
		(*env)->DeleteLocalRef(env,jconv);
		/* public void setSiteId(java.lang.String); */
		if (site_id != 1) {
			jmethodID  jsetSiteId = (*env)->GetMethodID(env,cls,"setSiteId","(Ljava/lang/String;)V");
			jstring jsiteId = (*env)->NewStringUTF(env,String_val(Field(site_id,0)));
			(*env)->CallVoidMethod(env,mt,jsetSiteId,jsiteId);
			(*env)->DeleteLocalRef(env,jsiteId);
		};
		(*env)->DeleteLocalRef(env,mt);
		(*env)->DeleteLocalRef(env,cls);
	};
}

void ml_MATsetUserId(value user_id) {
	if (!mobileTracker) caml_failwith("MobileAppTracker not initialized");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jmethodID setUserId = (*env)->GetMethodID(env,mobileTrackerCls,"setUserId","(Ljava/lang/String;)V");
	jobject juid = (*env)->NewStringUTF(env,String_val(user_id));
	(*env)->CallVoidMethod(env,setUserId,mobileTracker,setUserId,juid);
	(*env)->DeleteLocalRef(env,juid);
}

void ml_MATinstall(value unit) {
	PRINT_DEBUG("MAT INSTALL");
	if (!mobileTracker) caml_failwith("MobileAppTracker not initialized");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jmethodID trackInstall = (*env)->GetMethodID(env,mobileTrackerCls,"trackInstall","()I");
	PRINT_DEBUG("trackInstall: %d",trackInstall);
	(*env)->CallVoidMethod(env,mobileTracker,trackInstall);
}

void ml_MATupdate(value unit) {
	if (!mobileTracker) caml_failwith("MobileAppTracker not initialized");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jmethodID trackUpdate = (*env)->GetMethodID(env,mobileTrackerCls,"trackUpdate","()I");
	(*env)->CallVoidMethod(env,mobileTracker,trackUpdate);
}

