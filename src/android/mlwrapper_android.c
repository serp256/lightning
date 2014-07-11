
#include <unistd.h>
#include <fcntl.h>
#include <inttypes.h>
#include <pthread.h>
#include <sys/types.h>

#include <caml/custom.h>
#include "mlwrapper_android.h"
// #include "sound_android.h"
#include "assets_extractor.h"
#include "khash.h"
#include "mobile_res.h"
#include "engine.h"
#include <errno.h>
#include "render_stub.h"

#define caml_acquire_runtime_system()
#define caml_release_runtime_system()

JavaVM *gJavaVM;
jobject jActivity = NULL;
jobject jView = NULL;
jclass jViewCls = NULL;

static int ocaml_initialized = 0;
mlstage *stage = NULL;

typedef enum 
  { 
    St_int_val, 
    St_bool_val, 
    St_string_val, 
  } st_val_type;

static void mlUncaughtException(const char* exn, int bc, char** bv) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",exn);
	int i;
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	jclass jString = (*env)->FindClass(env,"java/lang/String");
	jobjectArray jbc = (*env)->NewObjectArray(env,bc,jString,NULL);
	for (i = 0; i < bc; i++) {
		if (bv[i]) {
			__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",bv[i]);
			jstring jbve = (*env)->NewStringUTF(env,bv[i]);
			(*env)->SetObjectArrayElement(env,jbc,i,jbve);
			(*env)->DeleteLocalRef(env,jbve);
		};
	};
	// Need to send email with this error and backtrace
	jstring jexn = (*env)->NewStringUTF(env,exn);
	jmethodID mlUncExn = (*env)->GetMethodID(env,jViewCls,"mlUncaughtException","(Ljava/lang/String;[Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env,jView,mlUncExn,jexn,jbc);
	(*env)->DeleteLocalRef(env,jbc);
	(*env)->DeleteLocalRef(env,jexn);
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	//__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	PRINT_DEBUG("JNI ON LOAD");
	uncaught_exception_callback = &mlUncaughtException;
	gJavaVM = vm;
	return JNI_VERSION_1_6; // Check this
}


jobject jApplicationContext(JNIEnv *env) {
	jclass jLightActivityCls = (*env)->GetObjectClass(env,jActivity);
	jmethodID jGetApplicationContextMethod = (*env)->GetMethodID(env,jLightActivityCls,"getApplicationContext","()Landroid/content/Context;");
	jobject res = (*env)->CallObjectMethod(env,jActivity,jGetApplicationContextMethod);
	(*env)->DeleteLocalRef(env,jLightActivityCls);
	return res;
}



/*
static size_t debug_tag_len = 0;
static char *debug_tag = NULL;
static size_t debug_address_len = 0;
static char *debug_address = NULL;
static size_t debug_msg_len = 0;
static char *debug_msg = NULL;
*/

/*
#define COPY_STRING(len,dst,src) \
		if (len < caml_string_length(src)) { \
			len = caml_string_length(src); \
			dst = realloc(dst, len + 1); \
		};\
		memcpy(dst,String_val(src),len);\
		dst[len] = '\0'
*/

value android_debug_output(value mtag, value mname, value mline, value msg) {
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else {
		tag = String_val(Field(mtag,0));
	};
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s(%s:%d)] %s",tag,String_val(mname),Int_val(mline),String_val(msg)); // this should be APPNAME
	return Val_unit;
}

value android_debug_output_info(value mname,value mline,value msg) {
	__android_log_print(ANDROID_LOG_INFO,"LIGHTNING","[%s:%d] %s",String_val(mname),Int_val(mline),String_val(msg));
	//fprintf(stderr,"INFO (%s) %s\n",String_val(mname),Int_val(mline),String_val(msg));
	return Val_unit;
}

value android_debug_output_warn(value mname,value mline,value msg) {
	__android_log_print(ANDROID_LOG_WARN,"LIGHTNING","[%s:%d] %s",String_val(mname),Int_val(mline),String_val(msg));
	return Val_unit;
}

value android_debug_output_error(value mname, value mline, value msg) {
	__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",String_val(msg));
	return Val_unit;
}

value android_debug_output_fatal(value mname, value mline, value msg) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",String_val(msg));
	return Val_unit;
}

/*static char* apk_path = NULL;
static char* main_exp_path = NULL;
static char* patch_exp_path = NULL;*/

KHASH_MAP_INIT_STR(res_index, offset_size_pair_t*);
static kh_res_index_t* res_indx;

#define JSTRING_TO_CSTRING(jstr, cstr)								\
	PRINT_DEBUG("xyupizda %s", #cstr);								\
	if (jstr) {														\
		PRINT_DEBUG("ok");											\
		_cstr = (*env)->GetStringUTFChars(env, jstr, JNI_FALSE);	\
		PRINT_DEBUG("%s",_cstr);									\
		len = (*env)->GetStringUTFLength(env, jstr);				\
		cstr = (char*)malloc(len + 1);								\
		strcpy(cstr, _cstr);										\
		(*env)->ReleaseStringUTFChars(env, jstr, _cstr);			\
	}																\

#define CAML_FAILWITH(...) {					\
	char* err_mes = (char*)malloc(255);			\
	sprintf(err_mes, __VA_ARGS__);				\
	return (*env)->NewStringUTF(env, err_mes);	\
}												\

JNIEXPORT jstring Java_ru_redspell_lightning_LightView_lightInit(JNIEnv *env, jobject jview, jobject jactivity, jobject storage, jlong j_indexOffset, jlong j_assetsOffset,
																jstring j_apkPath, jstring j_mainExpPath, jstring j_patchExpPath) {
	PRINT_DEBUG("lightInit");

/*	jActivity = (*env)->NewGlobalRef(env,jactivity);
	jView = (*env)->NewGlobalRef(env,jview);

	jclass viewCls = (*env)->GetObjectClass(env, jView);
	jViewCls = (*env)->NewGlobalRef(env, viewCls);
	PRINT_DEBUG("qweqweqwe");
	(*env)->DeleteLocalRef(env, viewCls);

	const char* _cstr;
	int len;

	JSTRING_TO_CSTRING(j_apkPath, apk_path);	
	JSTRING_TO_CSTRING(j_mainExpPath, main_exp_path);	
	JSTRING_TO_CSTRING(j_patchExpPath, patch_exp_path);	

	// PRINT_DEBUG("apk_path %s", apk_path);

	res_indx = kh_init_res_index();
	FILE* in = fopen(apk_path, "r");
	fseek(in, j_indexOffset, SEEK_SET);
	char* err = read_res_index(in, j_assetsOffset, -1);
	fclose(in);
	

	jstring retval = NULL;
	if (err) {
		retval = (*env)->NewStringUTF(env, err);
		free(err);
	}*/

	return NULL;
}

#define GET_FD(path)																	\
	if (!path) {																		\
		PRINT_DEBUG("path '%s' is NULL", #path);										\
		return 0;																		\
	}																					\
	fd = open(path, O_RDONLY);															\
	if (fd < 0) {																		\
		PRINT_DEBUG("failed to open path '%s' due to '%s'", path, strerror(errno));		\
		return 0;																		\
	}																					\

int getResourceFd(const char *path, resource *res) {
	offset_size_pair_t* os_pair;

	if (!get_offset_size_pair(path, &os_pair)) {
		int fd;

		if (os_pair->location == 0) {
			GET_FD(engine.apk_path);
		} else if (os_pair->location == 1) {
			GET_FD(engine.patch_exp_path)
		} else if (os_pair->location == 2) {
			GET_FD(engine.main_exp_path)
		} else {
			char* extra_res_fname = get_extra_res_fname(os_pair->location);
			if (!extra_res_fname) return 0;
			GET_FD(extra_res_fname);
		}

		lseek(fd, os_pair->offset, SEEK_SET);
		res->fd = fd;
		res->offset = os_pair->offset;
		res->length = os_pair->size;

		return 1;
	}

	return 0;
}


// получим параметры нах

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceCreated(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_nativeSurfaceCreated");
	if (!ocaml_initialized) {
		PRINT_DEBUG("init ocaml");
		char *argv[] = {"android",NULL};
		caml_startup(argv);
		// insert here get intent
		ocaml_initialized = 1;
		// get intent
		jclass jLightActivityCls = (*env)->GetObjectClass(env,jActivity);
		jmethodID jm = (*env)->GetMethodID(env,jLightActivityCls,"convertIntent","()V");
		(*env)->CallVoidMethod(env,jActivity,jm);
		(*env)->DeleteLocalRef(env,jLightActivityCls);
		PRINT_DEBUG("caml initialized");
	};
}

// static int onResume = 0;
// static int surfaceDestroyed = 0;
static int paused = 0;
static int started = 0;

JNIEXPORT void Java_ru_redspell_lightning_opengl_GLSurfaceView_00024GLThread_background(JNIEnv *env, jobject this) {
	static value dispatchBgHandler = 1;

	if (stage) {
		if (dispatchBgHandler == 1) dispatchBgHandler = caml_hash_variant("dispatchBackgroundEv");
		caml_callback2(caml_get_public_method(stage->stage, dispatchBgHandler), stage->stage, Val_unit);
	}
}

JNIEXPORT void Java_ru_redspell_lightning_opengl_GLSurfaceView_00024GLThread_foreground(JNIEnv *env, jobject this) {
	// first call should be ignored cause it is not foreground but application start
	if (!started) {
		started = 1;
		return;
	}

	static value dispatchFgHandler = 1;

	if (stage) {
		if (dispatchFgHandler == 1) dispatchFgHandler = caml_hash_variant("dispatchForegroundEv");
		caml_callback2(caml_get_public_method(stage->stage, dispatchFgHandler), stage->stage, Val_unit);
	}
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_nativeSurfaceChanged");
	PRINT_DEBUG("GL Changed: %i:%i, paused %d",width,height, paused);

	if (paused) {
		return;
	}

	if (!stage) {
		PRINT_DEBUG("create stage: [%d:%d]",width,height);
		stage = mlstage_create((float)width,(float)height); 
		PRINT_DEBUG("stage created");
	} else {
		float fwidth = (float)width;
		float fheight = (float)height;

		if (stage->width != fwidth || stage->height != fheight) {
			stage->width = width;
			stage->height = height;

			caml_callback3(caml_get_public_method(stage->stage, caml_hash_variant("_stageResized")), stage->stage, caml_copy_double(fwidth), caml_copy_double(fheight));
		}
	}

	PRINT_DEBUG("CALL FORCE");
	CAMLparam0();
	CAMLlocal1(reason);
	reason = caml_alloc_tuple(1);
	Store_field(reason, 0, caml_copy_string("surface changed"));
	caml_callback3(caml_get_public_method(stage->stage, caml_hash_variant("forceStageRender")), stage->stage, reason, Val_unit);
	CAMLreturn0;
}

JNIEXPORT jint Java_ru_redspell_lightning_LightRenderer_nativeGetFrameRate(JNIEnv *env, jobject this) {
	if (!stage) return 0;
	return mlstage_getFrameRate(stage);
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceDestroyed(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_nativeSurfaceDestroyed call");
}

extern int net_running();
extern void net_run();

 JNIEXPORT jboolean Java_ru_redspell_lightning_LightRenderer_nativeDrawFrame(JNIEnv *env, jobject thiz, jlong interval) {
    CAMLparam0();
	net_run();
	mlstage_advanceTime(stage, (double)interval / 1000000000L);
	mlstage_preRender();
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	restore_default_viewport();
	uint8_t retval = mlstage_render(stage);
    CAMLreturn(retval ? JNI_TRUE : JNI_FALSE);
}


// Touches 

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_fireTouch(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y, jint phase) {
	CAMLparam0();
	CAMLlocal3(globalX,globalY,touch);
	value touches = 1;
	touch = caml_alloc_tuple(8);
	globalX = caml_copy_double(x);
	globalY = caml_copy_double(y);
	Store_field(touch,0,caml_copy_int32(id + 1));
	Store_field(touch,1,caml_copy_double(0.));
	Store_field(touch,2,globalX);
	Store_field(touch,3,globalY);
	Store_field(touch,4,globalX);
	Store_field(touch,5,globalY);
	Store_field(touch,6,Val_int(1));// tap_count
	Store_field(touch,7,Val_int(phase)); 
	touches = caml_alloc_small(2,0);
	Field(touches,0) = touch;
	Field(touches,1) = 1; // None
  	mlstage_processTouches(stage,touches);
	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_fireTouches(JNIEnv *env, jobject thiz, jintArray jids, jfloatArray jxs, jfloatArray jys, jintArray jphases) {
	CAMLparam0();
	CAMLlocal5(touch,touches,globalX,globalY,timestamp);
	int size = (*env)->GetArrayLength(env,jids);
	jint ids[size];
	jfloat xs[size];
	jfloat ys[size];
	jint phases[size];
	(*env)->GetIntArrayRegion(env,jids,0,size,ids);
	(*env)->GetFloatArrayRegion(env,jxs,0,size,xs);
	(*env)->GetFloatArrayRegion(env,jys,0,size,ys);
	(*env)->GetIntArrayRegion(env,jphases,0,size,phases);
	value lst_el;
	int i = 0;
	touches = 1;
	timestamp = caml_copy_double(0.);
	for (i = 0; i < size; i++) {
		if (phases[i] != 2) {
			PRINT_DEBUG("touch with coord: %f:%f",xs[i],ys[i]);
			globalX = caml_copy_double(xs[i]);
			globalY = caml_copy_double(ys[i]);
			touch = caml_alloc_tuple(8);
			Store_field(touch,0,caml_copy_int32(ids[i] + 1));
			Store_field(touch,1,timestamp);
			Store_field(touch,2,globalX);
			Store_field(touch,3,globalY);
			Store_field(touch,4,globalX);
			Store_field(touch,5,globalY);
			Store_field(touch,6,Val_int(1));// tap_count
			Store_field(touch,7,Val_int(phases[i]));
			lst_el = caml_alloc_small(2,0);
			Field(lst_el,0) = touch;
			Field(lst_el,1) = touches;
			touches = lst_el;
		}
	}
  mlstage_processTouches(stage,touches);
	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_cancelAllTouches() {
	mlstage_cancelAllTouches(stage);
}

value ml_malinfo(value p) {
	return caml_alloc_tuple(3);
}

// JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnPause(JNIEnv *env, jobject this) {
// 	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnPause call");

// 	paused = 1;
// 	sound_pause(env);
// }


// JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnResume(JNIEnv *env, jobject this) {
// 	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnResume call");

// 	paused = 0;
// 	sound_resume(env);
// }

value ml_openURL(value  url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	char* curl = String_val(url);
	jstring jurl = (*env)->NewStringUTF(env, curl);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "openURL", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jurl);

	(*env)->DeleteLocalRef(env, jurl);
	return Val_unit;
}

value ml_addExceptionInfo (value info){
  	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cinfo = String_val(info);
	jstring jinfo = (*env)->NewStringUTF(env, cinfo);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlAddExceptionInfo", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jinfo);

	(*env)->DeleteLocalRef(env, jinfo);
	return Val_unit;
}

value ml_setSupportEmail (value d){
  JNIEnv *env;
	DEBUG("DDD: set support email");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cd = String_val(d);
	jstring jd = (*env)->NewStringUTF(env, cd);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlSetSupportEmail", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jd);

	(*env)->DeleteLocalRef(env, jd);	
	return Val_unit;
}

/*char* get_locale() {
	JNIEnv *env;
	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL); //it's possible to call this function from another thread, so to be sure, that env valid on any thread, call AttachCurrentThread instead of GetEnv
	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetLocale", "()Ljava/lang/String;");
	jstring locale = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env,locale,JNI_FALSE);
	char* retval = (char*)malloc(strlen(l) + 1);
	strcpy(retval, l);
	(*env)->ReleaseStringUTFChars(env, locale, l);
	(*env)->DeleteLocalRef(env, locale);

	return retval;		
}*/

/*NATIVEACTIVITY FIXME*/
value ml_getLocale () {
	return caml_copy_string("en");
	// char *c_locale = get_locale();
	// value v_locale = caml_copy_string(c_locale);
	// free(c_locale);
	// return v_locale;
}

value ml_getInternalStoragePath () {

	PRINT_DEBUG("GET INTERNAL STORAGE PATH");
	CAMLparam0();
	CAMLlocal1(r);

	JNIEnv *env;	
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetInternalStoragePath", "()Ljava/lang/String;");
	jstring path = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env, path, JNI_FALSE);

	r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env, path, l);
	(*env)->DeleteLocalRef(env, path);


	CAMLreturn(r);
}

value ml_getStoragePath () {

	CAMLparam0();
	CAMLlocal1(r);

	PRINT_DEBUG("GET STORAGE PATH");

	JNIEnv *env;	
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetStoragePath", "()Ljava/lang/String;");
	jstring path = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env, path, JNI_FALSE);

	r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env, path, l);
	(*env)->DeleteLocalRef(env, path);


	CAMLreturn(r);
}




static value ml_dispatchBackHandler = 1;

JNIEXPORT jboolean JNICALL Java_ru_redspell_lightning_LightRenderer_handleBack(JNIEnv *env, jobject this) {
	if (stage) {
		if (ml_dispatchBackHandler == 1) {
			ml_dispatchBackHandler = caml_hash_variant("dispatchBackPressedEv");
		}

		value res = caml_callback2(caml_get_public_method(stage->stage, ml_dispatchBackHandler), stage->stage, Val_unit);

		PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleBack %d", Bool_val(res));

		if (Bool_val(res)) exit(0);
	}

	return 1;
}


value ml_getVersion() {
	CAMLparam0();
	CAMLlocal1(version);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getVersion", "()Ljava/lang/String;");
	jstring jver = (*env)->CallObjectMethod(env, jView, mid);
	const char* cver = (*env)->GetStringUTFChars(env, jver, JNI_FALSE);
	// DEBUGF("cver %s", cver);
	version = caml_copy_string(cver);
	(*env)->ReleaseStringUTFChars(env, jver, cver);
	(*env)->DeleteLocalRef(env, jver);
	CAMLreturn(version);
}



/*
static value device_id;

value ml_device_id(value unit) {
	if (!device_id) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "device_id", "()Ljava/lang/String;");
		jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
		const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

		device_id = caml_copy_string(cdev);
		caml_register_generational_global_root(&device_id);

		(*env)->ReleaseStringUTFChars(env, jdev, cdev);
		(*env)->DeleteLocalRef(env, jdev);
	}

	return device_id;
}

static value mac_id;

value ml_getMACID(value unit) {
	DEBUGF("ML_MAC_ID");
	if (!mac_id) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "get_mac_id", "()Ljava/lang/String;");
		jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
		const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

		mac_id = caml_copy_string(cdev);
		caml_register_generational_global_root(&mac_id);

		(*env)->ReleaseStringUTFChars(env, jdev, cdev);
		(*env)->DeleteLocalRef(env, jdev);
	}

	return mac_id;
}
*/

value ml_getUDID(value unit) {
	DEBUGF("ML_UDID");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getUDID", "()Ljava/lang/String;");
	jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
	const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

	value udid = caml_copy_string(cdev);
	(*env)->ReleaseStringUTFChars(env, jdev, cdev);
	(*env)->DeleteLocalRef(env, jdev);
	return udid;
}

value ml_getOldUDID(value unit) {
	DEBUGF("ML_OLD_UDID");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getOldUDID", "()Ljava/lang/String;");
	jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
	const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

	value udid = caml_copy_string(cdev);

	(*env)->ReleaseStringUTFChars(env, jdev, cdev);
	(*env)->DeleteLocalRef(env, jdev);
	return udid;
}

value ml_androidScreen() {
	CAMLparam0();
	CAMLlocal1(andrScreen);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getScreen", "()I");
	int s = (int)(*env)->CallIntMethod(env, jView, mid);
	mid = (*env)->GetMethodID(env, jViewCls, "getDensity", "()I");
	int d = (int)(*env)->CallIntMethod(env, jView, mid);

	PRINT_DEBUG("s, d: %d %d", s, d);

	andrScreen = caml_alloc_tuple(2);
	Store_field(andrScreen, 0, Val_int(s));
	Store_field(andrScreen, 1, Val_int(d));

	CAMLreturn(andrScreen);
}

value ml_getDeviceType(value unit) {
	DEBUGF("ML_DEVICE_TYPE");
	CAMLparam0();
	CAMLlocal1(retval);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "isTablet", "()Z");
	jboolean jres = (*env)->CallBooleanMethod(env, jView, mid);

	if (jres) {
		retval = Val_int(1);
	} else {
		retval = Val_int(0);
	};
	//(*env)->DeleteLocalRef(env, jres);
	CAMLreturn(retval);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CamlFailwithRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID errMesFid;

	if (!errMesFid) {
		jclass selfCls = (*env)->GetObjectClass(env, this);
		errMesFid = (*env)->GetFieldID(env, selfCls, "errMes", "Ljava/lang/String;");
		(*env)->DeleteLocalRef(env, selfCls);
	}

	jstring jerrMes = (*env)->GetObjectField(env, this, errMesFid);
	const char* cerrMes = (*env)->GetStringUTFChars(env, jerrMes, JNI_FALSE);
	//value verrMes = caml_copy_string(cerrMes);

	(*env)->ReleaseStringUTFChars(env, jerrMes, cerrMes);
	(*env)->DeleteLocalRef(env, jerrMes);
	
	caml_failwith(cerrMes);
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_LightMediaPlayer_getOffsetSizePair(JNIEnv *env, jobject this, jstring path) {
	offset_size_pair_t* pair;
	const char* cpath = (*env)->GetStringUTFChars(env, path, JNI_FALSE);
	jobject retval = NULL;

	if (!get_offset_size_pair(cpath, &pair)) {
		static jclass offsetSizePairCls;
		static jmethodID offsetSizePairConstrMid;

		if (!offsetSizePairConstrMid) {
			jclass _offsetSizePairCls = (*env)->FindClass(env, "ru/redspell/lightning/LightMediaPlayer$OffsetSizePair");
			offsetSizePairCls = (*env)->NewGlobalRef(env, _offsetSizePairCls);
			(*env)->DeleteLocalRef(env, _offsetSizePairCls);
			offsetSizePairConstrMid = (*env)->GetMethodID(env, offsetSizePairCls, "<init>", "(III)V");
		}

		retval = (*env)->NewObject(env, offsetSizePairCls, offsetSizePairConstrMid, (jint)pair->offset, (jint)pair->size, (jint)pair->location);
	}

	(*env)->ReleaseStringUTFChars(env, path, cpath);
	return retval;
}

value ml_platform() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "platform", "()Ljava/lang/String;");

	jstring jplat = (*env)->CallStaticObjectMethod(env, jView, mid);
	const char* cplat = (*env)->GetStringUTFChars(env, jplat, JNI_FALSE);
	value retval = caml_copy_string(cplat);

	(*env)->ReleaseStringUTFChars(env, jplat, cplat);
	(*env)->DeleteLocalRef(env, jplat);

	return retval;
}

value ml_hwmodel() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "hwmodel", "()Ljava/lang/String;");

	jstring jmodel = (*env)->CallStaticObjectMethod(env, jView, mid);
	const char* cmodel = (*env)->GetStringUTFChars(env, jmodel, JNI_FALSE);
	value retval = caml_copy_string(cmodel);

	(*env)->ReleaseStringUTFChars(env, jmodel, cmodel);
	(*env)->DeleteLocalRef(env, jmodel);

	return retval;
}

value ml_totalMemory() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "totalMemory", "()J");
	jlong jtotalmem = (*env)->CallStaticLongMethod(env, jView, mid);

	return Val_long(jtotalmem);
}

JNIEXPORT jstring JNICALL Java_ru_redspell_lightning_LightView_glExts(JNIEnv *env, jobject this) {
	const char *exts = (char*)glGetString(GL_EXTENSIONS);
	return (*env)->NewStringUTF(env, exts);
}

value ml_showUrl(value v_url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "showUrl", "(Ljava/lang/String;)V");

	char* c_url = String_val(v_url);
	jstring j_url = (*env)->NewStringUTF(env, c_url);

	(*env)->CallVoidMethod(env, jView, mid, j_url);
	(*env)->DeleteLocalRef(env, j_url);
	return Val_unit;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExpansionsCompleteCallbackRunnable_run(JNIEnv *env, jobject this) {
    caml_callback(*caml_named_value("expansionsComplete"), Val_unit); 
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExpansionsProgressCallbackRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID totalFid = 0;
	static jfieldID progressFid = 0;
	static jfieldID timeRemainFid = 0;

	if (!totalFid) {
		jclass cls = (*env)->GetObjectClass(env, this);
		totalFid = (*env)->GetFieldID(env, cls, "total", "J");
		progressFid = (*env)->GetFieldID(env, cls, "progress", "J");
		timeRemainFid = (*env)->GetFieldID(env, cls, "timeRemain", "J");
		(*env)->DeleteLocalRef(env, cls);
	}

	jlong total = (*env)->GetIntField(env, this, totalFid);
	jlong progress = (*env)->GetIntField(env, this, progressFid);
	jlong timeRemain = (*env)->GetIntField(env, this, timeRemainFid);

    caml_callback3(*caml_named_value("expansionsProgress"), Val_int(total), Val_int(progress), Val_int(timeRemain));
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExpansionsErrorCallbackRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID fid = 0;

	if (!fid) {
		jclass cls = (*env)->GetObjectClass(env, this);
		fid = (*env)->GetFieldID(env, cls, "reason", "Ljava/lang/String;");
		(*env)->DeleteLocalRef(env, cls);
	}

	jstring j_reason = (*env)->GetObjectField(env, this, fid);
	const char* c_reason = (*env)->GetStringUTFChars(env, j_reason, JNI_FALSE);
	value v_reason = caml_copy_string(c_reason);
	(*env)->ReleaseStringUTFChars(env, j_reason, c_reason);

	caml_callback(*caml_named_value("expansionsError"), v_reason);
}

/*value ml_downloadExpansions(value v_pubkey) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "downloadExpansions", "(Ljava/lang/String;)V");

	jstring j_pubkey = (*env)->NewStringUTF(env, String_val(v_pubkey));
	(*env)->CallVoidMethod(env, jView, mid, j_pubkey);
	(*env)->DeleteLocalRef(env, j_pubkey);

	return Val_unit;
}*/

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightActivity_mlSetReferrer(JNIEnv *env, jobject this, jstring jtype, jstring jnid) {
	CAMLparam0();
	CAMLlocal2(mltype,mlnid);
	const char *type = (*env)->GetStringUTFChars(env,jtype,JNI_FALSE);
	const char *nid = (*env)->GetStringUTFChars(env,jnid,JNI_FALSE);
	PRINT_DEBUG("jtype %d %s", (int)type, type);
	PRINT_DEBUG("jnid %d %s", (int)nid, nid);

	PRINT_DEBUG("before copy");
	mltype = caml_copy_string(type);
	PRINT_DEBUG("after mltype copy");
	mlnid = caml_copy_string(nid);
	PRINT_DEBUG("after mlnid copy");
	set_referrer_ml(mltype,mlnid);
	PRINT_DEBUG("after set referrer ml");
	(*env)->DeleteLocalRef(env,jtype);
	(*env)->DeleteLocalRef(env,jnid);
	PRINT_DEBUG("success");
	CAMLreturn0;
}




value ml_show_nativeWait(value message) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "showNativeWait", "(Ljava/lang/String;)V");

	jstring jmsg = Is_block(message) ? (*env)->NewStringUTF(env,String_val(Field(message,0))) : NULL;

	(*env)->CallVoidMethod(env,jView,mid,NULL);	

	if (jmsg) (*env)->DeleteLocalRef(env,jmsg);
	return Val_unit;
}



value ml_hide_nativeWait(value p) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "hideNativeWait", "()V");

	(*env)->CallVoidMethod(env,jView,mid);	
	return Val_unit;
}



value ml_fire_lightning_event(value event_key) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "fireLightEvent", "(Ljava/lang/String;)V");
	jstring jevid = (*env)->NewStringUTF(env,String_val(event_key));
	(*env)->CallVoidMethod(env,jView,mid,jevid);
	(*env)->DeleteLocalRef(env,jevid);
	return Val_unit;
}



JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_fireNativeEvent(JNIEnv *env, jobject thiz, jstring jdata) {
	const char* cdata = (*env)->GetStringUTFChars(env, jdata, JNI_FALSE);
	value mldata = caml_copy_string(cdata);
	(*env)->ReleaseStringUTFChars(env,jdata,cdata);
	static value *mlfun = NULL;
	if (mlfun == NULL) mlfun = caml_named_value("on_native_event");
	caml_callback(*mlfun,mldata);
}

#define INVERSE_CASE_MID(method) static jmethodID mid = 0; \
	if (!mid) { \
		jclass cls = (*env)->FindClass(env, "java/lang/String"); \
		mid = (*env)->GetMethodID(env, cls, #method, "()Ljava/lang/String;"); \
		(*env)->DeleteLocalRef(env, cls); \
	}

#define INVERSE_CASE jstring jsrc = (*env)->NewStringUTF(env, String_val(vsrc)); \
	jstring jdst = (*env)->CallObjectMethod(env, jsrc, mid); \
	const char* cdst = (*env)->GetStringUTFChars(env, jdst, NULL); \
	vdst = caml_copy_string(cdst); \
	(*env)->ReleaseStringUTFChars(env, jdst, cdst); \
	(*env)->DeleteLocalRef(env, jsrc); \
	(*env)->DeleteLocalRef(env, jdst);

value ml_str_to_lower(value vsrc) {
	CAMLparam1(vsrc);
	CAMLlocal1(vdst);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	INVERSE_CASE_MID(toLowerCase);
	INVERSE_CASE;

	CAMLreturn(vdst);
}

value ml_str_to_upper(value vsrc) {
	CAMLparam1(vsrc);
	CAMLlocal1(vdst);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	INVERSE_CASE_MID(toUpperCase);
	INVERSE_CASE;

	CAMLreturn(vdst);
}

#undef INVERSE_CASE_MID
#undef INVERSE_CASE
