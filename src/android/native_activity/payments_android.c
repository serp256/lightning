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
	jobjectArray jskus = (*ML_ENV)->NewObjectArray(ML_ENV, skus_num, str_cls, NULL);

	int i;
	jstring jsku;
	for (i = 0; i < skus_num; i++) {
		jsku = (*ML_ENV)->NewStringUTF(ML_ENV, cskus[i]);
		(*ML_ENV)->SetObjectArrayElement(ML_ENV, jskus, i, jsku);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jsku);
	}

	if (Is_long(vmarket_type) && vmarket_type == caml_hash_variant("Amazon")) {
		payments_cls = lightning_find_class("ru/redspell/lightning/payments/amazon/Payments");
		jmethodID mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "<init>", "(Landroid/content/Context;)V");
		payments = (*ML_ENV)->NewObject(ML_ENV, payments_cls, mid, JAVA_ACTIVITY);
	} else if (Is_block(vmarket_type) && Field(vmarket_type, 0) == caml_hash_variant("Google")) {
		jstring jkey;
		value vkey = Field(vmarket_type, 1);

		if (vkey == Val_int(0)) {
			jkey = NULL;
		} else {
			char* ckey = String_val(Field(vkey, 0));
			jkey = (*ML_ENV)->NewStringUTF(ML_ENV, ckey);
		}

		payments_cls = lightning_find_class("ru/redspell/lightning/payments/google/Payments");
		jmethodID mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "<init>", "(Ljava/lang/String;)V");
		payments = (*ML_ENV)->NewObject(ML_ENV, payments_cls, mid, jkey);

		if (jkey != NULL) (*ML_ENV)->DeleteLocalRef(ML_ENV, jkey);
	} else {
		caml_failwith("something wrong with marketType, permited only '`Amazon' or '`Google of (option string)'");
	}

	jmethodID mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "init", "([Ljava/lang/String;)V");
	(*ML_ENV)->CallVoidMethod(ML_ENV, payments, mid, jskus);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jskus);

	CAMLreturn(Val_unit);
}

value ml_paymentsPurchase(value vsku) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "purchase", "(Ljava/lang/String;)V");

	jstring jsku = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vsku));
	(*ML_ENV)->CallVoidMethod(ML_ENV, payments, mid, jsku);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jsku);

	return Val_unit;
}

value ml_paymentsCommitTransaction(value vtoken) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "consumePurchase", "(Ljava/lang/String;)V");

	jstring jtoken = (*ML_ENV)->NewStringUTF(ML_ENV, String_val(vtoken));
	(*ML_ENV)->CallVoidMethod(ML_ENV, payments, mid, jtoken);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jtoken);	

	return Val_unit;
}

value ml_restorePurchases() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetMethodID(ML_ENV, payments_cls, "restorePurchases", "()V");

	(*ML_ENV)->CallVoidMethod(ML_ENV, payments, mid);

	return Val_unit;
}

typedef struct {
	jstring sku;
	jstring tid;
	jstring receipt;
	jstring sig;
	jboolean restored;
} success_t;

typedef struct {
	jstring sku;
	jstring reason;
} fail_t;

void reg_skus(void *data) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vprice);

	jobjectArray jskus = (jobjectArray)data;
	jsize len = (*ML_ENV)->GetArrayLength(ML_ENV, jskus);
	int i = 0;
	callback = *caml_named_value("register_product");

	while (i < len) {
		jstring jsku = (*ML_ENV)->GetObjectArrayElement(ML_ENV, jskus, i);
		jstring jprice = (*ML_ENV)->GetObjectArrayElement(ML_ENV, jskus, i + 1);
		const char* csku = (*ML_ENV)->GetStringUTFChars(ML_ENV, jsku, JNI_FALSE);
		const char* cprice = (*ML_ENV)->GetStringUTFChars(ML_ENV, jprice, JNI_FALSE);

		vsku = caml_copy_string(csku);
		vprice = caml_copy_string(cprice);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jsku, csku);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jprice, cprice);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jsku);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jprice);

		caml_callback2(callback, vsku, vprice);

		i += 2;
	}

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jskus);

	CAMLreturn0;
}

void payments_success(void *data) {
	CAMLparam0();
	CAMLlocal5(vsku, vtid, vreceipt, vsig, tr);
	CAMLlocal1(callback);

	success_t *s = (success_t*)data;
	JSTRING_TO_VAL(s->sku, vsku);
	JSTRING_TO_VAL(s->tid, vtid);
	JSTRING_TO_VAL(s->receipt, vreceipt);
	JSTRING_TO_VAL(s->sig, vsig);

	tr = caml_alloc_tuple(3);
	Store_field(tr, 0, vtid);
	Store_field(tr, 1, vreceipt);
	Store_field(tr, 2, vsig);

	callback = *caml_named_value("camlPaymentsSuccess");
	caml_callback3(callback, vsku, tr, s->restored == JNI_TRUE ? Val_true : Val_false);	

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, s->sku);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, s->tid);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, s->receipt);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, s->sig);
	free(s);

	CAMLreturn0;
}

void payments_fail(void *data) {
	CAMLparam0();
	CAMLlocal3(vsku, vreason, callback);

	fail_t *f = (fail_t*)data;
	JSTRING_TO_VAL(f->sku, vsku);
	JSTRING_TO_VAL(f->reason, vreason);

	callback = *caml_named_value("camlPaymentsFail");
	caml_callback3(callback, vsku, vreason, Val_false);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, f->sku);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, f->reason);
	free(f);

	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_success(JNIEnv *env, jobject this, jstring sku, jstring tid, jstring receipt, jstring sig, jboolean restored) {
	success_t *s = (success_t*)malloc(sizeof(success_t));

	s->sku = (*env)->NewGlobalRef(env, sku);
	s->tid = (*env)->NewGlobalRef(env, tid);
	s->receipt = (*env)->NewGlobalRef(env, receipt);
	s->sig = (*env)->NewGlobalRef(env, sig);
	s->restored = restored;
	
	RUN_ON_ML_THREAD(&payments_success, (void*)s);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_PaymentsCallbacks_fail(JNIEnv *env, jobject this, jstring sku, jstring reason) {
	fail_t *f = (fail_t*)malloc(sizeof(fail_t));

	f->sku = (*env)->NewGlobalRef(env, sku);
	f->reason = (*env)->NewGlobalRef(env, reason);

	RUN_ON_ML_THREAD(&payments_fail, (void*)f);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_google_Payments_00024SkuDetailsTask_nativeOnPostExecute(JNIEnv *env, jobject this, jobjectArray jskus) {
	RUN_ON_ML_THREAD(&reg_skus, (void*)(*env)->NewGlobalRef(env, jskus));
}
