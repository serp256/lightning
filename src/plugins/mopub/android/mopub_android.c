#include "mlwrapper_android.h"
#include <caml/custom.h>



static inline jclass lightMoPub_class(JNIEnv *env) {
	static jclass jLightMoPub = NULL;
	if (jLightMoPub == NULL) {
		jclass cls = (*env)->FindClass(env, "com/mopub/mobileads/LightningWrapper");
		jLightMoPub = (*env)->NewGlobalRef(env, cls);
		(*env)->DeleteLocalRef(env, cls);
	};
	return jLightMoPub;
}


#define BANNER(v) ((jobject*)Data_custom_val(v))

static inline jmethodID jDestroyBannerMethod(JNIEnv *env,jclass jLightMoPub) {
	static jmethodID m = NULL;
	if (m == NULL) {
		m = (*env)->GetStaticMethodID(env,jLightMoPub,"destroyBanner","(Lcom/mopub/mobileads/MoPubView;)V");
	}
	return m;
};

static void banner_finalize(value banner) {
	PRINT_DEBUG("finzalied banner %d",*BANNER(banner));
	jobject b = *BANNER(banner);
	if (b == NULL) return;
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	jmethodID m = jDestroyBannerMethod(env,jLightMoPub);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,m,b);
	(*env)->DeleteGlobalRef(env,b);
}

struct custom_operations banner_ops = {
  "pointer to java MoPubBanner object",
  banner_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

void ml_createMoPubBanner(value banner_id,value callback) {
	// сall method createBanner on LightMoPub
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jCreatBannerMethod = NULL;
	if (jCreatBannerMethod == NULL) {
		jCreatBannerMethod = (*env)->GetStaticMethodID(env, jLightMoPub, "createBanner","(Ljava/lang/String;I)V");
	};
	PRINT_DEBUG("convert string");
	jstring jBannerID = (*env)->NewStringUTF(env,String_val(banner_id));
	value *jcallback = malloc(sizeof(value));
	*jcallback = callback;
	caml_register_generational_global_root(jcallback);
	PRINT_DEBUG("call java method %d:%d",jLightMoPub,jCreatBannerMethod);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jCreatBannerMethod,jBannerID,(jint)jcallback);
	PRINT_DEBUG("JAVA METHOD CALLED");
	(*env)->DeleteLocalRef(env, jBannerID);
}



JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_bannerCreated(JNIEnv *env, jobject this, jobject jBanner, jint mlcallback) {
	PRINT_DEBUG("MOPUB BANNDER CREATED");
	value mlres = caml_alloc_custom(&banner_ops,sizeof(jobject),0,1);
	*BANNER(mlres)= (*env)->NewGlobalRef(env,jBanner);
	caml_callback(*(value*)mlcallback,mlres);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
}

void ml_loadMoPubBanner(value banner,value callback) {
	// call method load on banner
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("banner destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jLoadBannerMethod = NULL;
	if (jLoadBannerMethod == NULL) {
		jLoadBannerMethod = (*env)->GetStaticMethodID(env,jLightMoPub,"loadBanner","(Lcom/mopub/mobileads/MoPubView;I)V");
	};
	value *jcallback = malloc(sizeof(value));
	*jcallback = callback;
	caml_register_generational_global_root(jcallback);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jLoadBannerMethod,b,(jint)jcallback);
}


JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_00024BannerListener_ocamlOK(JNIEnv *env, jobject this, jint mlcallback) {
	PRINT_DEBUG("BannerListener_ocamlOK");
	value result = caml_hash_variant("success");
	caml_callback(*(value*)mlcallback,result);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
}

JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_00024BannerListener_ocamlError(JNIEnv *env, jobject this, jint mlcallback, jstring jerror) {
	PRINT_DEBUG("BannerListener_ocamlError");
	CAMLparam0();
	CAMLlocal1(res);
	res = caml_alloc_tuple(2);
	Field(res,0) = caml_hash_variant("error");
	const char* cerrMes = (*env)->GetStringUTFChars(env, jerror, JNI_FALSE);
	Store_field(res,1,caml_copy_string(cerrMes));
	(*env)->ReleaseStringUTFChars(env, jerror, cerrMes);
	caml_callback(*(value*)mlcallback,res);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
	CAMLreturn0;
}


void ml_showMoPubBanner(value banner, value x, value y) {
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("banner destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jShowBannerMethod = NULL;
	if (jShowBannerMethod == NULL) {
		jShowBannerMethod = (*env)->GetStaticMethodID(env,jLightMoPub,"showBanner","(Lcom/mopub/mobileads/MoPubView;II)V");
	};
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jShowBannerMethod,b,Long_val(x),Long_val(y));
}


void ml_hideMoPubBanner(value banner) {
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("banner destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jHideBannerMethod = NULL;
	if (jHideBannerMethod == NULL) {
		jHideBannerMethod = (*env)->GetStaticMethodID(env,jLightMoPub,"hideBanner","(Lcom/mopub/mobileads/MoPubView;)V");
	};
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jHideBannerMethod,b);
}


void ml_destroyMoPubBanner(value banner) {
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("banner destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	jmethodID m = jDestroyBannerMethod(env,jLightMoPub);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,m,b);
	(*env)->DeleteGlobalRef(env,b);
	*BANNER(banner) = NULL;
}


////////////////////////////////////
//  INTERSTITIAL
//  ///////////////////////////////

static inline jmethodID jDestroyInterstitialMethod(JNIEnv *env,jclass jLightMoPub) {
	static jmethodID m = NULL;
	if (m == NULL) {
		m = (*env)->GetStaticMethodID(env,jLightMoPub,"destroyInterstitial","(Lcom/mopub/mobileads/MoPubInterstitial;)V");
	}
	return m;
};

static void interstitial_finalize(value inters) {
	PRINT_DEBUG("finzalied interstition %d",*BANNER(inters));
	jobject b = *BANNER(inters);
	if (b == NULL) return;
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	jmethodID m = jDestroyInterstitialMethod(env,jLightMoPub);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,m,b);
	(*env)->DeleteGlobalRef(env,b);
}

static struct custom_operations interstitial_ops = {
  "pointer to java MoPubInterstitial object",
  interstitial_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

void ml_createMoPubInterstitial(value inters_id,value callback) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jCreateInterstitialMethod = NULL;
	if (jCreateInterstitialMethod == NULL) {
		jCreateInterstitialMethod = (*env)->GetStaticMethodID(env, jLightMoPub, "createInterstitial","(Ljava/lang/String;I)V");
	};
	jstring jBannerID = (*env)->NewStringUTF(env,String_val(inters_id));
	value *jcallback = malloc(sizeof(value));
	*jcallback = callback;
	caml_register_generational_global_root(jcallback);
	PRINT_DEBUG("call java method %d:%d",jLightMoPub,jCreateInterstitialMethod);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jCreateInterstitialMethod,jBannerID,(jint)jcallback);
	PRINT_DEBUG("JAVA METHOD CALLED");
	(*env)->DeleteLocalRef(env, jBannerID);
}

JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_interstitialCreated(JNIEnv *env, jobject this, jobject jInters, jint mlcallback) {
	PRINT_DEBUG("MOPUB INTERSTITIAL CREATED");
	value mlres = caml_alloc_custom(&interstitial_ops,sizeof(jobject),0,1);
	*BANNER(mlres)= (*env)->NewGlobalRef(env,jInters);
	caml_callback(*(value*)mlcallback,mlres);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
}

void ml_loadMoPubInterstitial(value inters,value callback) {
	// call method load on banner
	jobject b = *BANNER(inters);
	if (b == NULL) caml_failwith("interstitial destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jLoadInterstitialMethod = NULL;
	if (jLoadInterstitialMethod == NULL) {
		jLoadInterstitialMethod = (*env)->GetStaticMethodID(env,jLightMoPub,"loadInterstitial","(Lcom/mopub/mobileads/MoPubInterstitial;I)V");
	};
	value *jcallback = malloc(sizeof(value));
	*jcallback = callback;
	caml_register_generational_global_root(jcallback);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jLoadInterstitialMethod,b,(jint)jcallback);
}


JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_00024InterstitialListener_ocamlOK(JNIEnv *env, jobject this, jint mlcallback) {
	PRINT_DEBUG("InterstitialListener_ocamlOK");
	value result = caml_hash_variant("success");
	caml_callback(*(value*)mlcallback,result);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
}

JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_00024InterstitialListener_ocamlError(JNIEnv *env, jobject this, jint mlcallback, jstring jerror) {
	PRINT_DEBUG("InterstitialListener_ocamlError");
	CAMLparam0();
	CAMLlocal1(res);
	res = caml_alloc_tuple(2);
	Field(res,0) = caml_hash_variant("error");
	const char* cerrMes = (*env)->GetStringUTFChars(env, jerror, JNI_FALSE);
	Store_field(res,1,caml_copy_string(cerrMes));
	(*env)->ReleaseStringUTFChars(env, jerror, cerrMes);
	caml_callback(*(value*)mlcallback,res);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_com_mopub_mobileads_LightningWrapper_00024InterstitialListener_ocamCallback(JNIEnv *env, jobject this, jint mlcallback) {
	PRINT_DEBUG("InterstitialListener_dismiss");
	caml_callback(*(value*)mlcallback,1);
	caml_remove_generational_global_root((value*)mlcallback);
	free((value*)mlcallback);
}


void ml_showMoPubInterstitial(value banner,value callback) {
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("interstitial destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	static jmethodID jShowInterstitialMethod = NULL;
	if (jShowInterstitialMethod == NULL) {
		jShowInterstitialMethod = (*env)->GetStaticMethodID(env,jLightMoPub,"showInterstitial","(Lcom/mopub/mobileads/MoPubInterstitial;I)V");
	};
	value *c = malloc(sizeof(value));
	*c = callback;
	caml_register_generational_global_root(c);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,jShowInterstitialMethod,b,(jint)c);
}

void ml_destroyMoPubInterstitial(value banner) {
	jobject b = *BANNER(banner);
	if (b == NULL) caml_failwith("interstitial destroyed");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	jmethodID m = jDestroyInterstitialMethod(env,jLightMoPub);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,m,b);
	(*env)->DeleteGlobalRef(env,b);
	*BANNER(banner) = NULL;
}
