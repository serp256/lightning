#define RESOURCE_CHECK(transaction) if (*((jobject*)Data_custom_val(transaction)) == NULL) caml_invalid_argument("given transaction already comsumed, cannot comsume again or access its fields");

#include "lightning_android.h"
#include "engine_android.h"
#include "plugin_common.h"

static jclass cls = NULL;
#define GET_CLS cls = engine_find_class("ru/redspell/lightning/plugins/LightGameanalytics");

jobjectArray getStringArray (value varray) {
	jstring jstrArray[50];
	GET_ENV;

	int arrIndex = 0;

	if (varray != Val_int(0)) {
			PRINT_DEBUG("chckpnt2.1");

			value v_head = Field(varray, 0);
			value vstr;

			PRINT_DEBUG("chckpnt2.2");

			while (Is_block(v_head)) {
					vstr= Field(v_head, 0);
					PRINT_DEBUG("str %s", String_val(vstr));

					jstring jstr;
					jstr = (*env)->NewStringUTF(env, String_val(vstr));
					jstrArray[arrIndex++] = jstr;
					v_head= Field(v_head, 1);
			}
			PRINT_DEBUG("chckpnt3");

			jclass stringCls = (*env)->FindClass(env, "java/lang/String");
			jobjectArray jarray = (*env)->NewObjectArray(env, arrIndex, stringCls, NULL);

			int i;

			for (i = 0; i < arrIndex; i++) {
					PRINT_DEBUG("4.1");

					(*env)->SetObjectArrayElement(env, jarray, i, jstrArray[i]);
					PRINT_DEBUG("4.2");
					(*env)->DeleteLocalRef(env, jstrArray[i]);
					PRINT_DEBUG("4.3");
			}

			PRINT_DEBUG("chckpnt4");
			return jarray;
	}
	PRINT_DEBUG("chckpnt fail");
	return NULL;
}

value ml_ga_init (value vkey, value vsecret, value vversion, value vdebug, value vcurrencies, value vitemTypes, value vdimensions) {
	CAMLparam5(vkey, vsecret, vversion, vdebug, vcurrencies);
	CAMLxparam2(vitemTypes, vdimensions);
	PRINT_DEBUG("ml_ga_init");

	GET_ENV;
	GET_CLS;


	jobjectArray jcurrencies = getStringArray (vcurrencies);
	jobjectArray jitemTypes= getStringArray (vitemTypes);
	jobjectArray jdimensions= getStringArray (vdimensions);

	STATIC_MID(cls, init, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z[Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;)V");
	jstring jkey     = (*env)->NewStringUTF(env, String_val(vkey));
	jstring jsecret  = (*env)->NewStringUTF(env, String_val(vsecret));

	
	jstring jversion = Is_block(vversion) ? (*env)->NewStringUTF(env, String_val(Field(vversion,0))) : JNI_FALSE;
	if (jversion == JNI_FALSE) {
		caml_failwith ("GameAnalyrics android version cannot be null");
	}
	jboolean jdebug = Bool_val(vdebug) ? JNI_TRUE: JNI_FALSE;

	char* java_exn_message = engine_handle_java_expcetion();
	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jkey, jsecret, jversion, jdebug, jcurrencies, jitemTypes, jdimensions);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);
	(*env)->DeleteLocalRef(env, jkey);
	(*env)->DeleteLocalRef(env, jsecret);
	(*env)->DeleteLocalRef(env, jversion);
	(*env)->DeleteLocalRef(env, jcurrencies);
	(*env)->DeleteLocalRef(env, jitemTypes);
	(*env)->DeleteLocalRef(env, jdimensions);

	CAMLreturn(Val_unit);
}

value ml_ga_init_byte(value* argv, int argn) {
	PRINT_DEBUG("ml_ga_init_byte");
    return ml_ga_init (argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}


value ml_ga_business_event (value vcartType, value vitemType, value vitemId, value vcurrency, value vamount, value vreceipt, value vsignature) {
	CAMLparam5(vcartType, vitemType, vitemId, vcurrency, vamount);
	CAMLxparam2(vreceipt, vsignature);
	PRINT_DEBUG("ml_ga_business_event");

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, businessEvent, "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;)V");
	jstring jcartType     = (*env)->NewStringUTF(env, String_val(vcartType));
	jstring jitemType  = (*env)->NewStringUTF(env, String_val(vitemType));
	jstring jitemId  = (*env)->NewStringUTF(env, String_val(vitemId));
	jstring jcurrency  = (*env)->NewStringUTF(env, String_val(vcurrency));
	jstring jreceipt  = (*env)->NewStringUTF(env, String_val(vreceipt));
	jstring jsignature  = (*env)->NewStringUTF(env, String_val(vsignature));
	jint jamount = (jint) (Int_val(vamount));

	char* java_exn_message = engine_handle_java_expcetion();
	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jcartType, jitemType, jitemId, jcurrency, jamount, jreceipt, jsignature);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);
	(*env)->DeleteLocalRef(env, jcartType);
	(*env)->DeleteLocalRef(env, jitemType);
	(*env)->DeleteLocalRef(env, jitemId);
	(*env)->DeleteLocalRef(env, jcurrency);
	(*env)->DeleteLocalRef(env, jreceipt);
	(*env)->DeleteLocalRef(env, jsignature);

	CAMLreturn(Val_unit);
}

value ml_ga_business_event_byte(value* argv, int argn) {
	PRINT_DEBUG("ml_ga_business_event_byte");
    return ml_ga_business_event (argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}


value ml_ga_resource_event (value vflowType, value vcurrency, value vamount, value vitemType, value vitemId) {
	CAMLparam5(vflowType, vcurrency, vamount, vitemType, vitemId);
	PRINT_DEBUG("ml_ga_resource_event");

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, resourceEvent, "(ILjava/lang/String;DLjava/lang/String;Ljava/lang/String;)V");

	jint jflowType;

	if (vflowType == caml_hash_variant("sink")) {
		jflowType = 0;
	} else if (vflowType == caml_hash_variant("source")) {
		jflowType = 1;
	} else {
			caml_failwith("GameAnalytics: Invalid resourceEvent hash variant");
		}


	jstring jcurrency  = (*env)->NewStringUTF(env, String_val(vcurrency));
	jstring jitemType  = (*env)->NewStringUTF(env, String_val(vitemType));
	jstring jitemId  = (*env)->NewStringUTF(env, String_val(vitemId));

	jdouble jamount = (jdouble) (Double_val(vamount));

	if (jamount <= 0) {
		caml_failwith("Invalid amount: cannot be 0 or negative");
	}

	char* java_exn_message = engine_handle_java_expcetion();
	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jflowType, jcurrency, jamount, jitemType, jitemId);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);

	(*env)->DeleteLocalRef(env, jcurrency);
	(*env)->DeleteLocalRef(env, jitemType);
	(*env)->DeleteLocalRef(env, jitemId);

	CAMLreturn(Val_unit);
}


value ml_ga_progression_event (value vstatus, value vprogression1, value vprogression2, value vprogression3, value vscore) {
	CAMLparam5(vstatus, vprogression1, vprogression2, vprogression3, vscore);
	PRINT_DEBUG("ml_ga_progression_event");

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, progressionEvent, "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/Integer;)V");

	jint jstatus;

	if (vstatus== caml_hash_variant("start")) {
		jstatus = 0;
	} else if (vstatus == caml_hash_variant("complete")) {
		jstatus = 1;
	} else if (vstatus == caml_hash_variant("fail")) {
		jstatus = -1;
	} else {
			caml_failwith("GameAnalytics: Invalid progressionEvent hash variant");
		}


	jstring jprogression1  = (*env)->NewStringUTF(env, String_val(vprogression1));
	jstring jprogression2 = Is_block(vprogression2) ? (*env)->NewStringUTF(env, String_val(Field(vprogression2,0))) : JNI_FALSE;
	jstring jprogression3 = Is_block(vprogression3) ? (*env)->NewStringUTF(env, String_val(Field(vprogression3,0))) : JNI_FALSE;

	//jint jscore = Is_block(vscore) ? (jint) (Int_val(vscore)) : JNI_FALSE;
	//
	jclass jicls = (*env)->FindClass(env, "java/lang/Integer");
	 
	jmethodID midInit = (*env)->GetMethodID(env, jicls, "<init>", "(I)V");
	jobject jscore = Is_block(vscore) ? (*env)->NewObject(env, jicls, midInit, (jint) (Int_val(Field(vscore,0)))) : JNI_FALSE;

	char* java_exn_message = engine_handle_java_expcetion();
	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jstatus, jprogression1, jprogression2, jprogression3, jscore);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);

	(*env)->DeleteLocalRef(env, jprogression1);
	(*env)->DeleteLocalRef(env, jprogression2);
	(*env)->DeleteLocalRef(env, jprogression3);
	(*env)->DeleteLocalRef(env, jscore);

	CAMLreturn(Val_unit);
}



value ml_ga_design_event (value vevType, value vf) {
	CAMLparam2(vevType, vf);
	PRINT_DEBUG("ml_ga_design_event");

	GET_ENV;
	GET_CLS;

	STATIC_MID(cls, designEvent, "(Ljava/lang/String;Ljava/lang/Double;)V");

	jstring jevType  = (*env)->NewStringUTF(env, String_val(vevType));

	jclass jicls = (*env)->FindClass(env, "java/lang/Double");
	 
	jmethodID midInit = (*env)->GetMethodID(env, jicls, "<init>", "(D)V");
	jobject jf = Is_block(vf) ? (*env)->NewObject(env, jicls, midInit,(jdouble) (Double_val(Field(vf,0)))) : JNI_FALSE;

	char* java_exn_message = engine_handle_java_expcetion();

	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jevType, jf);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);

	(*env)->DeleteLocalRef(env, jevType);
	(*env)->DeleteLocalRef(env, jf);
	CAMLreturn(Val_unit);
}


value ml_ga_error_event (value vevType, value vmessage) {
	CAMLparam2(vevType, vmessage);
	PRINT_DEBUG("ml_ga_error_event");

	GET_ENV;
	GET_CLS;

	jint jevType;

	if (vevType== caml_hash_variant("edebug")) {
		jevType = 0;
	} else if (vevType == caml_hash_variant("info")) {
		jevType = 1;
	} else if (vevType == caml_hash_variant("warning")) {
		jevType = 2;
	} else if (vevType == caml_hash_variant("error")) {
		jevType = 3;
	} else if (vevType == caml_hash_variant("critical")) {
		jevType = 4;
	} else {
			caml_failwith("GameAnalytics: Invalid errorEvent hash variant");
		}


	STATIC_MID(cls, errorEvent, "(ILjava/lang/String;)V");

	jstring jmessage = Is_block (vmessage) ? (*env)->NewStringUTF(env, String_val(Field(vevType,0))) : JNI_FALSE;

	char* java_exn_message = engine_handle_java_expcetion();

	PRINT_DEBUG("call");
	(*env)->CallStaticVoidMethod(env, cls, mid, jevType, jmessage);
	PRINT_DEBUG("after call");
	if (java_exn_message) caml_failwith(java_exn_message);

	(*env)->DeleteLocalRef(env, jmessage);
	CAMLreturn(Val_unit);
}
