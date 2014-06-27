#include "payments_android.h"

/*
void ml_paymentsTest() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jmethodID mthdId = (*env)->GetMethodID(env, jViewCls, "initBillingServ", "()V");
	(*env)->CallIntMethod(env, jView, mthdId);
}
*/

// static value successCb = 0;
// static value errorCb = 0;

// void ml_payment_init(value pubkey, value scb, value ecb) {

// 	if (successCb == 0) {
// 		successCb = scb;
// 		caml_register_generational_global_root(&successCb);
// 		errorCb = ecb;
// 		caml_register_generational_global_root(&errorCb);
// 	} else {
// 		caml_modify_generational_global_root(&successCb,scb);
// 		caml_modify_generational_global_root(&errorCb,ecb);
// 	}

// 	if (!Is_long(pubkey)) {
// 		JNIEnv *env;
// 		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

// 		jclass securityCls = (*env)->FindClass(env, "ru/redspell/lightning/payments/Security");
// 		jmethodID setPubkey = (*env)->GetStaticMethodID(env, securityCls, "setPubkey", "(Ljava/lang/String;)V");
// 		char* cpubkey = String_val(Field(pubkey, 0));
// 		jstring jpubkey = (*env)->NewStringUTF(env, cpubkey);

// 		(*env)->CallStaticVoidMethod(env, securityCls, setPubkey, jpubkey);

// 		(*env)->DeleteLocalRef(env, securityCls);
// 		(*env)->DeleteLocalRef(env, jpubkey);
// 	}
// }

// void payments_destroy() {
// 	if (successCb) {
// 		caml_remove_generational_global_root(&successCb);
// 		successCb = 0;
// 		caml_remove_generational_global_root(&errorCb);
// 		errorCb = 0;
// 	};
// }

// static jmethodID gRequestPurchase;

// void ml_payment_purchase(value prodId) {
// 	JNIEnv *env;
// 	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

// 	if (gRequestPurchase == NULL) {
// 		gRequestPurchase = (*env)->GetMethodID(env, jViewCls, "requestPurchase", "(Ljava/lang/String;)V");
// 	}

// 	char* cprodId = String_val(prodId);

// 	PRINT_DEBUG("requesting product id %s", cprodId);

// 	jstring jprodId = (*env)->NewStringUTF(env, cprodId);
// 	(*env)->CallVoidMethod(env, jView, gRequestPurchase, jprodId);

// 	(*env)->DeleteLocalRef(env, jprodId);
// }

// JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb(JNIEnv *env, jobject this, jstring prodId, jstring notifId, jstring signedData, jstring signature) {
// 	CAMLparam0();
// 	CAMLlocal2(tr, vprodId);

// 	DEBUGF("Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb %d", gettid());

// 	if (!successCb) return; //caml_failwith("payment callbacks are not initialized");

// 	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
// 	const char *cnotifId = (*env)->GetStringUTFChars(env, notifId, JNI_FALSE);
// 	const char *csignature = (*env)->GetStringUTFChars(env, signature, JNI_FALSE);
// 	const char *csignedData = (*env)->GetStringUTFChars(env, signedData, JNI_FALSE);	

// 	tr = caml_alloc_tuple(3);
// 	vprodId = caml_copy_string(cprodId);

// 	Store_field(tr, 0, caml_copy_string(cnotifId));
// 	Store_field(tr, 1, caml_copy_string(csignedData));
// 	Store_field(tr, 2, caml_copy_string(csignature));

// 	caml_callback3(successCb, vprodId, tr, Val_true);

// 	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
// 	(*env)->ReleaseStringUTFChars(env, notifId, cnotifId);
// 	(*env)->ReleaseStringUTFChars(env, signature, csignature);
// 	(*env)->ReleaseStringUTFChars(env, signedData, csignedData);

// 	DEBUG("return jni invoke caml payment succ cb");

// 	CAMLreturn0;
// }

// JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentErrorCb(JNIEnv *env, jobject this, jstring prodId, jstring mes) {
// 	DEBUG("jni invoke caml payment error cb");

// 	CAMLparam0();
// 	CAMLlocal2(vprodId, vmes);

// 	if (!errorCb) return; 
// 	//	caml_failwith("payment callbacks are not initialized");

// 	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
// 	const char *cmes = (*env)->GetStringUTFChars(env, mes, JNI_FALSE);

// 	vprodId = caml_copy_string(cprodId);
// 	vmes = caml_copy_string(cmes);

// 	caml_callback3(errorCb, vprodId, vmes, Val_true);

// 	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
// 	(*env)->ReleaseStringUTFChars(env, mes, cmes);

// 	DEBUG("return jni invoke caml payment err cb");

// 	CAMLreturn0;
// }

// static jmethodID gConfirmNotif;

// void ml_payment_commit_transaction(value transaction) {
// 	CAMLparam1(transaction);
// 	CAMLlocal1(vnotifId);

// 	JNIEnv *env;
// 	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

// 	if (gConfirmNotif == NULL) {
// 		gConfirmNotif = (*env)->GetMethodID(env, jViewCls, "confirmNotif", "(Ljava/lang/String;)V");
// 	}

// 	// vnotifId = Field(transaction, 0);
// 	char* cnotifId = String_val(transaction);
// 	jstring jnotifId = (*env)->NewStringUTF(env, cnotifId);
// 	(*env)->CallVoidMethod(env, jView, gConfirmNotif, jnotifId);

// 	(*env)->DeleteLocalRef(env, jnotifId);

// 	CAMLreturn0;
// }

// void ml_restoreTransactions() {
// 	JNIEnv *env;
// 	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

// 	static jmethodID mid;

// 	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "restoreTransactions", "()V");
// 	(*env)->CallVoidMethod(env, jView, mid);
// }

value ml_paymentsInit(value vskus, value marketType) {
	CAMLparam0();
	CAMLlocal1(vsku);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	PRINT_DEBUG("ML PAYMENTS INIT");

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "paymentsInit", "(ZLjava/lang/String;[Ljava/lang/String;)V");

	int skus_num = 0;
	char* cskus[255];

	if (Is_block(vskus)) {
		vsku = Field(vskus, 0);
		while (Is_block(vsku)) {
			cskus[skus_num++] = String_val(Field(vsku, 0));
			vsku = Field(vsku, 1);
		}
	}

	static jclass jstringCls = NULL;
	if (!jstringCls) {
		jclass cls = (*env)->FindClass(env, "java/lang/String");
		jstringCls = (*env)->NewGlobalRef(env, cls);
		(*env)->DeleteLocalRef(env, cls);
	}

	PRINT_DEBUG("1");
	jobjectArray jskus = (*env)->NewObjectArray(env, skus_num, jstringCls, NULL);
	PRINT_DEBUG("2");

	int i;
	jstring jsku;
	for (i = 0; i < skus_num; i++) {
		PRINT_DEBUG("3");
		jsku = (*env)->NewStringUTF(env, cskus[i]);
		(*env)->SetObjectArrayElement(env, jskus, i, jsku);
		(*env)->DeleteLocalRef(env, jsku);
	}

	if (Is_long(marketType) && marketType == caml_hash_variant("Amazon")) {
		PRINT_DEBUG("INIT AMAZON");
		(*env)->CallVoidMethod(env, jView, mid, JNI_FALSE, NULL, jskus);
	} else if (Is_block(marketType) && Field(marketType, 0) == caml_hash_variant("Google")) {
		jstring j_key;
		value v_key = Field(marketType, 1);

		if (v_key == Val_int(0)) {
			j_key = NULL;
		} else {
			char* c_key = String_val(Field(v_key, 0));
			j_key = (*env)->NewStringUTF(env, c_key);
		}

		(*env)->CallVoidMethod(env, jView, mid, JNI_TRUE, j_key, jskus);
		(*env)->DeleteLocalRef(env, jskus);

		if (j_key != NULL) {
			(*env)->DeleteLocalRef(env, j_key);
		}
	} else {
		caml_failwith("something wrong with marketType, permited only '`Amazon' or '`Google of (option string)'");
	}

	PRINT_DEBUG("6");

	CAMLreturn(Val_unit);
}

value ml_paymentsPurchase(value sku) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "paymentsPurchase", "(Ljava/lang/String;)V");

	char* c_sku = String_val(sku);
	jstring j_sku = (*env)->NewStringUTF(env, c_sku);

	(*env)->CallVoidMethod(env, jView, mid, j_sku);
	(*env)->DeleteLocalRef(env, j_sku);

	return Val_unit;
}

value ml_paymentsCommitTransaction(value purchaseToken) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "paymentsConsumePurchase", "(Ljava/lang/String;)V");

	char* c_purchaseToken = String_val(purchaseToken);
	jstring j_purchaseToken = (*env)->NewStringUTF(env, c_purchaseToken);

	(*env)->CallVoidMethod(env, jView, mid, j_purchaseToken);
	(*env)->DeleteLocalRef(env, j_purchaseToken);
	return Val_unit;
}

value ml_restorePurchases() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "restorePurchases", "()V");

	(*env)->CallVoidMethod(env, jView, mid);

	PRINT_DEBUG("ml_restorePurchase done");

	return Val_unit;
}

JNIEXPORT void Java_ru_redspell_lightning_payments_LightPaymentsCamlCallbacks_00024Success_run(JNIEnv *env, jobject this) {
	static jfieldID skuFid = 0;
	static jfieldID transactionIdFid = 0;
	static jfieldID receiptFid = 0;
	static jfieldID signatureFid = 0;
	static jfieldID restoredFid = 0;

	if (!skuFid) {
		jclass cls = (*env)->GetObjectClass(env, this);

		GET_FID(sku)
		GET_FID(transactionId)
		GET_FID(receipt)
		GET_FID(signature)
		restoredFid = (*env)->GetFieldID(env, cls, "restored", "Z");

		(*env)->DeleteLocalRef(env, cls);
	}

	JNI_TO_VAL(sku)
	JNI_TO_VAL(transactionId)
	JNI_TO_VAL(receipt)
	JNI_TO_VAL(signature)
	jboolean j_restored = (*env)->GetBooleanField(env, this, restoredFid); 

	value transaction = caml_alloc_tuple(3);

	Store_field(transaction, 0, v_transactionId);
	Store_field(transaction, 1, v_receipt);
	Store_field(transaction, 2, v_signature);

	value* cb = caml_named_value("camlPaymentsSuccess");
	if (!cb) caml_failwith("payments success callback not specified");
	caml_callback3(*cb, v_sku, transaction, j_restored == JNI_TRUE ? Val_true : Val_false);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_LightPaymentsCamlCallbacks_00024Fail_run(JNIEnv *env, jobject this) {
	static jfieldID skuFid = 0;
	static jfieldID reasonFid = 0;

	if (!skuFid) {
		jclass cls = (*env)->GetObjectClass(env, this);

		GET_FID(sku)
		GET_FID(reason)

		(*env)->DeleteLocalRef(env, cls);
	}

	JNI_TO_VAL(sku)
	JNI_TO_VAL(reason)

	value* cb = caml_named_value("camlPaymentsFail");
	if (!cb) caml_failwith("payments fail callback not specified");
	caml_callback3(*cb, v_sku, v_reason, Val_false);	
}

JNIEXPORT void Java_ru_redspell_lightning_payments_google_LightGooglePayments_registerProduct(JNIEnv *env, jobject this, jstring jsku, jstring jprice) {
	static value* cb = NULL;
	if (!cb) cb = caml_named_value("register_product");

	const char* csku = (*env)->GetStringUTFChars(env, jsku, JNI_FALSE);
	const char* cprice = (*env)->GetStringUTFChars(env, jprice, JNI_FALSE);
	value vsku = caml_copy_string(csku);
	value vprice = caml_copy_string(cprice);
	(*env)->ReleaseStringUTFChars(env, jsku, csku);
	(*env)->ReleaseStringUTFChars(env, jprice, cprice);

	caml_callback2(*cb, vsku, vprice);
}
