#include "mlwrapper_android.h"

void ml_paymentsTest() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jmethodID mthdId = (*env)->GetMethodID(env, jViewCls, "initBillingServ", "()V");
	(*env)->CallIntMethod(env, jView, mthdId);
}

static value successCb = 0;
static value errorCb = 0;

void ml_payment_init(value pubkey, value scb, value ecb) {

	if (successCb == 0) {
		successCb = scb;
		caml_register_generational_global_root(&successCb);
		errorCb = ecb;
		caml_register_generational_global_root(&errorCb);
	} else {
		caml_modify_generational_global_root(&successCb,scb);
		caml_modify_generational_global_root(&errorCb,ecb);
	}

	if (!Is_long(pubkey)) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		jclass securityCls = (*env)->FindClass(env, "ru/redspell/lightning/payments/Security");
		jmethodID setPubkey = (*env)->GetStaticMethodID(env, securityCls, "setPubkey", "(Ljava/lang/String;)V");
		char* cpubkey = String_val(Field(pubkey, 0));
		jstring jpubkey = (*env)->NewStringUTF(env, cpubkey);

		(*env)->CallStaticVoidMethod(env, securityCls, setPubkey, jpubkey);

		(*env)->DeleteLocalRef(env, securityCls);
		(*env)->DeleteLocalRef(env, jpubkey);
	}
}

void payments_destroy() {
	if (successCb) {
		caml_remove_generational_global_root(&successCb);
		successCb = 0;
		caml_remove_generational_global_root(&errorCb);
		errorCb = 0;
	};
}

static jmethodID gRequestPurchase;

void ml_payment_purchase(value prodId) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gRequestPurchase == NULL) {
		gRequestPurchase = (*env)->GetMethodID(env, jViewCls, "requestPurchase", "(Ljava/lang/String;)V");
	}

	char* cprodId = String_val(prodId);

	PRINT_DEBUG("requesting product id %s", cprodId);

	jstring jprodId = (*env)->NewStringUTF(env, cprodId);
	(*env)->CallVoidMethod(env, jView, gRequestPurchase, jprodId);

	(*env)->DeleteLocalRef(env, jprodId);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb(JNIEnv *env, jobject this, jstring prodId, jstring notifId, jstring signedData, jstring signature) {
	CAMLparam0();
	CAMLlocal2(tr, vprodId);

	DEBUGF("Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb %d", gettid());

	if (!successCb) return; //caml_failwith("payment callbacks are not initialized");

	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
	const char *cnotifId = (*env)->GetStringUTFChars(env, notifId, JNI_FALSE);
	const char *csignature = (*env)->GetStringUTFChars(env, signature, JNI_FALSE);
	const char *csignedData = (*env)->GetStringUTFChars(env, signedData, JNI_FALSE);	

	tr = caml_alloc_tuple(3);
	vprodId = caml_copy_string(cprodId);

	Store_field(tr, 0, caml_copy_string(cnotifId));
	Store_field(tr, 1, caml_copy_string(csignedData));
	Store_field(tr, 2, caml_copy_string(csignature));

	caml_callback3(successCb, vprodId, tr, Val_true);

	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
	(*env)->ReleaseStringUTFChars(env, notifId, cnotifId);
	(*env)->ReleaseStringUTFChars(env, signature, csignature);
	(*env)->ReleaseStringUTFChars(env, signedData, csignedData);

	DEBUG("return jni invoke caml payment succ cb");

	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentErrorCb(JNIEnv *env, jobject this, jstring prodId, jstring mes) {
	DEBUG("jni invoke caml payment error cb");

	CAMLparam0();
	CAMLlocal2(vprodId, vmes);

	if (!errorCb) return; 
	//	caml_failwith("payment callbacks are not initialized");

	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
	const char *cmes = (*env)->GetStringUTFChars(env, mes, JNI_FALSE);

	vprodId = caml_copy_string(cprodId);
	vmes = caml_copy_string(cmes);

	caml_callback3(errorCb, vprodId, vmes, Val_true);

	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
	(*env)->ReleaseStringUTFChars(env, mes, cmes);

	DEBUG("return jni invoke caml payment err cb");

	CAMLreturn0;
}

static jmethodID gConfirmNotif;

void ml_payment_commit_transaction(value transaction) {
	CAMLparam1(transaction);
	CAMLlocal1(vnotifId);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gConfirmNotif == NULL) {
		gConfirmNotif = (*env)->GetMethodID(env, jViewCls, "confirmNotif", "(Ljava/lang/String;)V");
	}

	// vnotifId = Field(transaction, 0);
	char* cnotifId = String_val(transaction);
	jstring jnotifId = (*env)->NewStringUTF(env, cnotifId);
	(*env)->CallVoidMethod(env, jView, gConfirmNotif, jnotifId);

	(*env)->DeleteLocalRef(env, jnotifId);

	CAMLreturn0;
}

void ml_restoreTransactions() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid;

	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "restoreTransactions", "()V");
	(*env)->CallVoidMethod(env, jView, mid);
}