#include "lightning_android.h"
#include "engine.h"
#include <caml/alloc.h>

static jclass payments_cls = NULL;
static jobject payments = NULL;

value ml_paymentsInit(value vskus, value vmarket_type) {
	CAMLparam2(vskus, vmarket_type);
	CAMLlocal1(vsku);

	int skus_num = 0;
	char* cskus[255];

	if (Is_block(vskus)) {
		vsku = Field(vskus, 0);
		while (Is_block(vsku)) {
			cskus[skus_num++] = String_val(Field(vsku, 0));
			vsku = Field(vsku, 1);
		}
	}

	jclass str_cls = lightning_find_class("java/lang/String");
	jobjectArray jskus = (*ENV)->NewObjectArray(ENV, skus_num, str_cls, NULL);

	int i;
	jstring jsku;
	for (i = 0; i < skus_num; i++) {
		jsku = (*ENV)->NewStringUTF(ENV, cskus[i]);
		(*ENV)->SetObjectArrayElement(ENV, jskus, i, jsku);
		(*ENV)->DeleteLocalRef(ENV, jsku);
	}

	if (Is_long(vmarket_type) && vmarket_type == caml_hash_variant("Amazon")) {
		payments_cls = lightning_find_class("ru/redspell/lightning/payments/amazon/Payments");
		jmethodID mid = (*ENV)->GetMethodID(ENV, payments_cls, "<init>", "(Landroid/content/Context;)V");
		payments = (*ENV)->NewObject(ENV, payments_cls, mid, JAVA_ACTIVITY);
	} else if (Is_block(vmarket_type) && Field(vmarket_type, 0) == caml_hash_variant("Google")) {
		jstring jkey;
		value vkey = Field(vmarket_type, 1);

		if (vkey == Val_int(0)) {
			jkey = NULL;
		} else {
			char* ckey = String_val(Field(vkey, 0));
			jkey = (*ENV)->NewStringUTF(ENV, ckey);
		}

		payments_cls = lightning_find_class("ru/redspell/lightning/payments/google/Payments");
		jmethodID mid = (*ENV)->GetMethodID(ENV, payments_cls, "<init>", "(Ljava/lang/String;)V");
		payments = (*ENV)->NewObject(ENV, payments_cls, mid, jkey);

		if (jkey != NULL) (*ENV)->DeleteLocalRef(ENV, jkey);
	} else {
		caml_failwith("something wrong with marketType, permited only '`Amazon' or '`Google of (option string)'");
	}

	jmethodID mid = (*ENV)->GetMethodID(ENV, payments_cls, "init", "([Ljava/lang/String;)V");
	(*ENV)->CallVoidMethod(ENV, payments, mid, jskus);
	(*ENV)->DeleteLocalRef(ENV, jskus);

	CAMLreturn(Val_unit);
}

void reg_skus(void *data) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vprice);

	jobjectArray jskus = (jobjectArray)data;
	jsize len = (*ENV)->GetArrayLength(ENV, jskus);
	int i = 0;
	callback = *caml_named_value("register_product");

	while (i < len) {
		jstring jsku = (*ENV)->GetObjectArrayElement(ENV, jskus, i);
		jstring jprice = (*ENV)->GetObjectArrayElement(ENV, jskus, i + 1);
		const char* csku = (*ENV)->GetStringUTFChars(ENV, jsku, JNI_FALSE);
		const char* cprice = (*ENV)->GetStringUTFChars(ENV, jprice, JNI_FALSE);

		vsku = caml_copy_string(csku);
		vprice = caml_copy_string(cprice);
		(*ENV)->ReleaseStringUTFChars(ENV, jsku, csku);
		(*ENV)->ReleaseStringUTFChars(ENV, jprice, cprice);
		(*ENV)->DeleteLocalRef(ENV, jsku);
		(*ENV)->DeleteLocalRef(ENV, jprice);

		caml_callback2(callback, vsku, vprice);

		i += 2;
	}

	(*ENV)->DeleteGlobalRef(ENV, jskus);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_google_Payments_00024SkuDetailsTask_nativeOnPostExecute(JNIEnv *env, jobject this, jobjectArray jskus) {
	lightning_runonmlthread(&reg_skus, (void*)(*env)->NewGlobalRef(env, jskus));
}

/*value ml_paymentsPurchase(value vsku) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ENV)->GetMethodID(ENV, payments_cls, "purchase", "(Ljava/lang/String;)V");

	jstring jsku = (*ENV)->NewStringUTF(ENV, String_val(vsku));
	(*ENV)->CallVoidMethod(ENV, payments, mid, jsku);
	(*ENV)->DeleteLocalRef(ENV, jsku);

	return Val_unit;
}

value ml_paymentsCommitTransaction(value vtoken) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ENV)->GetMethodID(ENV, payments_cls, "consumePurchase", "(Ljava/lang/String;)V");

	jstring jtoken = (*ENV)->NewStringUTF(ENV, String_val(vtoken));
	(*ENV)->CallVoidMethod(ENV, payments, mid, jtoken);
	(*ENV)->DeleteLocalRef(ENV, jtoken);

	return Val_unit;
}

value ml_restorePurchases() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ENV)->GetMethodID(ENV, payments_cls, "restorePurchases", "()V");

	(*ENV)->CallVoidMethod(ENV, payments, mid);

	return Val_unit;
}

struct {
	jstring sku;
	jstring tid;
	jstring receipt;
	jstring sig;
	jstring restored;
} success_t;

struct {
	jstring sku;
	jstring reason;
} fail_t;

JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_success(JNIEnv *env, jobject this, jstring sku, jstring tid, jstring receipt, jstring sig, jboolean restored) {
	// success_t *success = (success_t*)malloc(sizeof(success_t));

	// success.sku = sku;
	// success.tid = tid;
	// success.receipt = receipt;
	// success.sig = sig;
	// success.restored = restored;
	
	android_app_write_cmd(engine.app, LIGTNING_CMD_PAYMENT_SUCCESS);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_fail(JNIEnv *env, jobject this, jstring sku, jstring reason) {
}*/

/*JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_00024Success_run(JNIEnv *env, jobject this) {
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

JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_00024Fail_run(JNIEnv *env, jobject this) {
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

JNIEXPORT void Java_ru_redspell_lightning_payments_google_Payments_registerProduct(JNIEnv *env, jobject this, jstring jsku, jstring jprice) {
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
*/