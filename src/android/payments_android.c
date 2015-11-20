#include "lightning_android.h"
#include "engine_android.h"
#include <caml/custom.h>

//same as OpenIabHelper class constants
#define GOOGLE "com.google.play"
#define AMAZON "com.amazon.apps"
#define SAMSUNG "com.samsung.apps"
#define SAMSUNG_DEV "com.samsung.apps.dev"
#define YANDEX "com.yandex.store"
#define NOKIA "com.nokia.nstore"
#define APPLAND "Appland"
#define SLIDEME "SlideME"
#define APTOIDE "cm.aptoide.pt"

static jclass payments_cls = 0;
#define FIND_PAYMENTS_CLASS if (!payments_cls) payments_cls = engine_find_class("ru/redspell/lightning/payments/Payments")

value openiab_init(value vskus, value vmarket_type) {
	int skus_num = 0;
	char* cskus[255];
	value vsku;

	if (Is_block(vskus)) {
		vsku = Field(vskus, 0);
		while (Is_block(vsku)) {
			cskus[skus_num++] = String_val(Field(vsku, 0));
			vsku = Field(vsku, 1);
		}
	}

	jclass str_cls = engine_find_class("java/lang/String");
	jobjectArray jskus = (*ML_ENV)->NewObjectArray(ML_ENV, skus_num, str_cls, NULL);

	int i;
	jstring jsku;
	for (i = 0; i < skus_num; i++) {
		jsku = (*ML_ENV)->NewStringUTF(ML_ENV, cskus[i]);
		(*ML_ENV)->SetObjectArrayElement(ML_ENV, jskus, i, jsku);
		(*ML_ENV)->DeleteLocalRef(ML_ENV, jsku);
	}

	char *cmarket_type = "";

	if (vmarket_type == caml_hash_variant("Google")) {
		cmarket_type = GOOGLE;
	} else if (vmarket_type == caml_hash_variant("Amazon")) {
		cmarket_type = AMAZON;
	} else if (vmarket_type == caml_hash_variant("Yandex")) {
		cmarket_type = YANDEX;
	}  else if (vmarket_type == caml_hash_variant("Samsung")) {
		cmarket_type = SAMSUNG;
	} else if (vmarket_type == caml_hash_variant("SamsungDev")) {
		cmarket_type = SAMSUNG_DEV;
	}

	jstring jmarket_type = (*ML_ENV)->NewStringUTF(ML_ENV, cmarket_type);

	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "init", "([Ljava/lang/String;Ljava/lang/String;)V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, payments_cls, mid, jskus, jmarket_type);


	char* java_exn_message = engine_handle_java_expcetion();

	PRINT_DEBUG ("1");
//	(*ML_ENV)->DeleteLocalRef(ML_ENV, str_cls);
	PRINT_DEBUG ("2");
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jskus);
	PRINT_DEBUG ("3");
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jmarket_type);

	if (java_exn_message) caml_failwith(java_exn_message);

	return Val_unit;
}

value openiab_purchase(value vsku) {
	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "purchase", "(Ljava/lang/String;)V");

	jstring jsku;
	VAL_TO_JSTRING(vsku, jsku);

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, payments_cls, mid, jsku);
	char* java_exn_message = engine_handle_java_expcetion();
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jsku);
	if (java_exn_message) caml_failwith(java_exn_message);

	return Val_unit;
}

static void payment_transaction_finalize(value vtransaction) {
	jobject jtransaction = *((jobject*)Data_custom_val(vtransaction));
	if (jtransaction) {
		(*ML_ENV)->DeleteGlobalRef(ML_ENV, jtransaction);
	}
}

struct custom_operations payment_transaction_ops = {
	"pointer to payment transaction",
	payment_transaction_finalize,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default
};

#define ARSENY_POKAYOKE(transaction) if (*((jobject*)Data_custom_val(transaction)) == NULL) caml_invalid_argument("given transaction already comsumed, cannot comsume again or access its fields");
#define JTransaction_val(transaction) *((jobject*)Data_custom_val(transaction))

value openiab_comsume(value vtransaction) {
	ARSENY_POKAYOKE(vtransaction);

	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "consume", "(Ljava/lang/Object;)V");

	jobject jtransaction = *((jobject*)Data_custom_val(vtransaction));
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, payments_cls, mid, jtransaction);
	char* java_exn_message = engine_handle_java_expcetion();
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, jtransaction);
	*((jobject*)Data_custom_val(vtransaction)) = NULL;

	if (java_exn_message) caml_failwith(java_exn_message);

	return Val_unit;
}

value openiab_inventory(value unit) {
	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "inventory", "()V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, payments_cls, mid);

	char* java_exn_message = engine_handle_java_expcetion();
	if (java_exn_message) caml_failwith(java_exn_message);

	return Val_unit;
}

value openiab_orig_json(value vpurchase) {
	ARSENY_POKAYOKE(vpurchase);

	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "getOriginalJson", "(Ljava/lang/Object;)Ljava/lang/String;");

	jstring jorig_json = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, payments_cls, mid, JTransaction_val(vpurchase));
	char* java_exn_message = engine_handle_java_expcetion();
	if (java_exn_message) caml_failwith(java_exn_message);

	value vorig_json;
	JSTRING_TO_VAL(jorig_json, vorig_json);

	return vorig_json;
}

value openiab_token(value vpurchase) {
	ARSENY_POKAYOKE(vpurchase);

	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "getToken", "(Ljava/lang/Object;)Ljava/lang/String;");

	jstring jtoken = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, payments_cls, mid, JTransaction_val(vpurchase));
	char* java_exn_message = engine_handle_java_expcetion();
	if (java_exn_message) caml_failwith(java_exn_message);

	value vtoken;
	JSTRING_TO_VAL(jtoken, vtoken);

	return vtoken;
}

value openiab_signature(value vpurchase) {
	ARSENY_POKAYOKE(vpurchase);

	FIND_PAYMENTS_CLASS;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, payments_cls, "getSignature", "(Ljava/lang/Object;)Ljava/lang/String;");

	jstring jsignature = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, payments_cls, mid, JTransaction_val(vpurchase));
	char* java_exn_message = engine_handle_java_expcetion();
	if (java_exn_message) caml_failwith(java_exn_message);

	value vsignature;
	JSTRING_TO_VAL(jsignature, vsignature);

	return vsignature;
}

typedef struct {
	jstring sku;
	jobject purchase;
	value restored;
} openiab_success_t;

typedef struct {
	jstring sku;
	jstring reason;
} openiab_fail_t;

typedef struct {
	jstring sku;
	jstring price;
} openiab_register_t;

typedef struct {
	jstring sku;
	jobject details;
} openiab_register_details_t;

void openiab_success(void *d) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vtransaction);

	openiab_success_t *data = (openiab_success_t*)d;
	callback = *caml_named_value("camlPaymentsSuccess");
	JSTRING_TO_VAL(data->sku, vsku);

	vtransaction = caml_alloc_custom(&payment_transaction_ops, sizeof(jobject), 0, 1);
	*((jobject*)Data_custom_val(vtransaction)) = data->purchase;

	caml_callback3(callback, vsku, vtransaction, data->restored);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->sku);
	free(data);

	CAMLreturn0;
}

void openiab_fail(void *d) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vreason);

	openiab_fail_t *data = (openiab_fail_t*)d;
	callback = *caml_named_value("camlPaymentsFail");
	JSTRING_TO_VAL(data->reason, vreason);
	JSTRING_TO_VAL(data->sku, vsku);
	caml_callback3(callback, vsku, vreason, Val_false);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->reason);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->sku);
	free(data);

	CAMLreturn0;
}

void openiab_register(void *d) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vprice);

	openiab_register_t *data = (openiab_register_t*)d;
	callback = *caml_named_value("register_product");
	JSTRING_TO_VAL(data->price, vprice);
	JSTRING_TO_VAL(data->sku, vsku);
	caml_callback2(callback, vsku, vprice);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->price);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->sku);
	free(data);

	CAMLreturn0;
}

void openiab_register_details(void *d) {
	CAMLparam0();
	CAMLlocal3(callback, vsku, vdetails);

	PRINT_DEBUG ("openiab_register_details");
	openiab_register_details_t *data = (openiab_register_details_t*)d;
	callback = *caml_named_value("register_product_details");
	JSTRING_TO_VAL(data->sku, vsku);

	static value* create_details = NULL;
	if (!create_details) create_details= caml_named_value("create_product_details");


	static jfieldID currency_fid = 0;
	static jfieldID amount_fid = 0;

 	if (!currency_fid) {
		jclass details_cls = engine_find_class("ru/redspell/lightning/payments/Payments$LightDetails");

		currency_fid = (*ML_ENV)->GetFieldID(ML_ENV, details_cls, "currency", "Ljava/lang/String;");
		amount_fid = (*ML_ENV)->GetFieldID(ML_ENV, details_cls, "amount", "D");
	}

	jstring jcurrency = (jstring)(*ML_ENV)->GetObjectField(ML_ENV, data->details, currency_fid);
	const char* ccurrency= (*ML_ENV)->GetStringUTFChars(ML_ENV, jcurrency, JNI_FALSE);
	jdouble jamount = (*ML_ENV)->GetDoubleField(ML_ENV, data->details, amount_fid);

	value args[2] = { caml_copy_string(ccurrency),caml_copy_double((double)jamount)};
	caml_callback2(callback, vsku, caml_callbackN(*create_details, 2, args));

	(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jcurrency, ccurrency);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jcurrency);

	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->details);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->sku);

	free(data);

	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_Payments_purchaseSuccess(JNIEnv *env, jclass this, jstring jsku, jobject jpurchase, jboolean jrestored) {
	openiab_success_t *data = (openiab_success_t*)malloc(sizeof(openiab_success_t));
	data->purchase = (*env)->NewGlobalRef(env, jpurchase);
	data->sku = (*env)->NewGlobalRef(env, jsku);
	data->restored = jrestored == JNI_TRUE ? Val_true : Val_false;

	RUN_ON_ML_THREAD(&openiab_success, (void*)data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_Payments_purchaseFail(JNIEnv *env, jclass this, jstring jsku, jstring jreason) {
	openiab_fail_t *data = (openiab_fail_t*)malloc(sizeof(openiab_fail_t));
	data->reason = (*env)->NewGlobalRef(env, jreason);
	data->sku = (*env)->NewGlobalRef(env, jsku);

	RUN_ON_ML_THREAD(&openiab_fail, (void*)data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_Payments_purchaseRegister(JNIEnv *env, jclass this, jstring jsku, jstring jprice) {
	PRINT_DEBUG("Java_ru_redspell_lightning_payments_openiab_Openiab_purchaseRegister call");
	openiab_register_t *data = (openiab_register_t*)malloc(sizeof(openiab_register_t));
	data->price = (*env)->NewGlobalRef(env, jprice);
	data->sku = (*env)->NewGlobalRef(env, jsku);

	RUN_ON_ML_THREAD(&openiab_register, (void*)data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_payments_Payments_purchaseDetailsRegister(JNIEnv *env, jclass this, jstring jsku, jobject jdetails) {
	PRINT_DEBUG("Java_ru_redspell_lightning_payments_openiab_Openiab_purchaseDetailsRegister call");
	openiab_register_details_t *data = (openiab_register_details_t*)malloc(sizeof(openiab_register_details_t));
	data->details= (*env)->NewGlobalRef(env, jdetails);
	data->sku = (*env)->NewGlobalRef(env, jsku);

	RUN_ON_ML_THREAD(&openiab_register_details, (void*)data);
}
