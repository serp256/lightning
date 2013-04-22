
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <inttypes.h>
#include <pthread.h>
#include <sys/types.h>

#include <caml/custom.h>
#include "mlwrapper.h"
#include "mlwrapper_android.h"
#include "net_curl.h"
#include "assets_extractor.h"
#include "khash.h"
#include "mobile_res.h"

#define caml_acquire_runtime_system()
#define caml_release_runtime_system()

JavaVM *gJavaVM;
jobject jView = NULL;
jclass jViewCls = NULL;

static int ocaml_initialized = 0;
static mlstage *stage = NULL;

/*static jobject jStorage;
static jobject jStorageEditor;*/

static jclass gSndPoolCls = NULL;
static jobject gSndPool = NULL;


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

jclass get_lmp_class() {
	static jclass lmpCls;

	if (!lmpCls) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);	
		lmpCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "ru/redspell/lightning/LightMediaPlayer"));
	}

	return lmpCls;
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

void android_debug_output(value mtag, value mname, value mline, value msg) {
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else {
		tag = String_val(Field(mtag,0));
	};
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s(%s:%d)] %s",tag,String_val(mname),Int_val(mline),String_val(msg)); // this should be APPNAME
	//fprintf(stderr,"%s (%s) %s\n",tag,String_val(address),String_val(msg));
}

void android_debug_output_info(value mname,value mline,value msg) {
	__android_log_print(ANDROID_LOG_INFO,"LIGHTNING","[%s:%d] %s",String_val(mname),Int_val(mline),String_val(msg));
	//fprintf(stderr,"INFO (%s) %s\n",String_val(mname),Int_val(mline),String_val(msg));
}

void android_debug_output_warn(value mname,value mline,value msg) {
	__android_log_print(ANDROID_LOG_WARN,"LIGHTNING","[%s:%d] %s",String_val(mname),Int_val(mline),String_val(msg));
	//fprintf(stderr,"WARN (%s) %s\n",String_val(mname),Int_val(mline),String_val(msg));
}

void android_debug_output_error(value mname, value mline, value msg) {
	__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",String_val(msg));
	//fprintf(stderr,"ERROR (%s) %s\n",String_val(mname),Int_val(mline),String_val(msg));
}

void android_debug_output_fatal(value mname, value mline, value msg) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",String_val(msg));
	//fprintf(stderr,"FATAL (%s) %s\n",String_val(mname),Int_val(mline),String_val(msg));
}

static char* apk_path = NULL;
static char* main_exp_path = NULL;
static char* patch_exp_path = NULL;

KHASH_MAP_INIT_STR(res_index, offset_size_pair_t*);
static kh_res_index_t* res_indx;

#define JSTRING_TO_CSTRING(jstr, cstr)								\
	PRINT_DEBUG("xyupizda %s", #cstr);								\
	if (jstr) {														\
		PRINT_DEBUG("ok");											\
		_cstr = (*env)->GetStringUTFChars(env, jstr, JNI_FALSE);	\
		PRINT_DEBUG("%s",_cstr);									\
		len = (*env)->GetStringUTFLength(env, jstr);				\
		cstr = (char*)malloc(len);									\
		strcpy(cstr, _cstr);										\
		(*env)->ReleaseStringUTFChars(env, jstr, _cstr);			\
	}																\

#define CAML_FAILWITH(...) {					\
	char* err_mes = (char*)malloc(255);			\
	sprintf(err_mes, __VA_ARGS__);				\
	return (*env)->NewStringUTF(env, err_mes);	\
}												\

JNIEXPORT jstring Java_ru_redspell_lightning_LightView_lightInit(JNIEnv *env, jobject jview, jobject storage, jlong j_indexOffset, jlong j_assetsOffset,
																jstring j_apkPath, jstring j_mainExpPath, jstring j_patchExpPath) {
	PRINT_DEBUG("lightInit");

	jView = (*env)->NewGlobalRef(env,jview);

	jclass viewCls = (*env)->GetObjectClass(env, jView);
	jViewCls = (*env)->NewGlobalRef(env, viewCls);

	const char* _cstr;
	int len;

	JSTRING_TO_CSTRING(j_apkPath, apk_path);	
	JSTRING_TO_CSTRING(j_mainExpPath, main_exp_path);	
	JSTRING_TO_CSTRING(j_patchExpPath, patch_exp_path);	

	PRINT_DEBUG("apk_path %s", apk_path);

	res_indx = kh_init_res_index();
	FILE* in = fopen(apk_path, "r");
	fseek(in, j_indexOffset, SEEK_SET);
	read_res_index(in, j_assetsOffset);
	fclose(in);
	
	/* shared preferences 
	jStorage = (*env)->NewGlobalRef(env, storage);
	jclass storageCls = (*env)->GetObjectClass(env, storage);
	jmethodID jmthd_edit = (*env)->GetMethodID(env, storageCls, "edit", "()Landroid/content/SharedPreferences$Editor;");
	jobject storageEditor = (*env)->CallObjectMethod(env, storage, jmthd_edit);
	jStorageEditor = (*env)->NewGlobalRef(env, storageEditor);
	(*env)->DeleteLocalRef(env, storageCls);
	(*env)->DeleteLocalRef(env, storageEditor);*/
	(*env)->DeleteLocalRef(env, viewCls);
}

#define GET_FD(PATH)								\
	if (!PATH) {									\
		PRINT_DEBUG("path '%s' is NULL", #PATH);	\
		return 0;									\
	}												\
	fd = open(PATH, O_RDONLY);						\

int getResourceFd(const char *path, resource *res) {
	offset_size_pair_t* os_pair;

	if (!get_offset_size_pair(path, &os_pair)) {
		int fd;

		if (os_pair->location == 0) {
			GET_FD(apk_path)
		} else if (os_pair->location == 1) {
			GET_FD(patch_exp_path)
		} else if (os_pair->location == 2) {
			GET_FD(main_exp_path)
		} else {
			PRINT_DEBUG("unknown location value in offset-size pair for path %s", path);
			return 0;
		}

		lseek(fd, os_pair->offset, SEEK_SET);

		res->fd = fd;
		res->length = os_pair->size;

		return 1;
	}

	return 0;
}


// получим параметры нах

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceCreated(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("lightRender init");
	if (!ocaml_initialized) {
		PRINT_DEBUG("init ocaml");
		char *argv[] = {"android",NULL};
		caml_startup(argv);
		ocaml_initialized = 1;
		PRINT_DEBUG("caml initialized");
	};
}

static int onResume = 0;
static int surfaceDestroyed = 0;

void callDispatchFgHandler() {
	static value dispatchFgHandler = 1;

	if (stage) {
		if (dispatchFgHandler == 1) dispatchFgHandler = caml_hash_variant("dispatchForegroundEv");
		caml_callback2(caml_get_public_method(stage->stage, dispatchFgHandler), stage->stage, Val_unit);
	}	
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("GL Changed: %i:%i",width,height);

	if (!stage) {
		PRINT_DEBUG("create stage: [%d:%d]",width,height);
		stage = mlstage_create((float)width,(float)height); 
		PRINT_DEBUG("stage created");
	} else if (onResume) {
		onResume = 0;
		callDispatchFgHandler();
	}

}

JNIEXPORT jint Java_ru_redspell_lightning_LightRenderer_nativeGetFrameRate(JNIEnv *env, jobject this) {
	if (!stage) return 0;
	return mlstage_getFrameRate(stage);
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceDestroyed(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_nativeSurfaceDestroyed call");
	surfaceDestroyed = 1;
}




static value run_method = 1;//None
//void mlstage_run(double timePassed) {
//}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeDrawFrame(JNIEnv *env, jobject thiz, jlong interval) {
	CAMLparam0();
	CAMLlocal1(timePassed);
	// PRINT_DEBUG("DRAW FRAME!!!!");
	timePassed = caml_copy_double((double)interval / 1000000000L);
	//mlstage_run(timePassed);
	if (net_running > 0) net_perform();
	if (run_method == 1) run_method = caml_hash_variant("run");
	caml_callback2(caml_get_public_method(stage->stage,run_method),stage->stage,timePassed);
	// PRINT_DEBUG("caml run ok");
	CAMLreturn0;
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

void ml_alsoundInit() {
	if (!gSndPool) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		jclass amCls = (*env)->FindClass(env, "android/media/AudioManager");
		jfieldID strmTypeFid = (*env)->GetStaticFieldID(env, amCls, "STREAM_MUSIC", "I");
		jint strmType = (*env)->GetStaticIntField(env, amCls, strmTypeFid);

		jclass sndPoolCls = (*env)->FindClass(env, "android/media/SoundPool");
		jmethodID constrId = (*env)->GetMethodID(env, sndPoolCls, "<init>", "(III)V");
		jobject sndPool = (*env)->NewObject(env, sndPoolCls, constrId, 100, strmType, 0);

		gSndPoolCls = (*env)->NewGlobalRef(env, sndPoolCls);
		gSndPool = (*env)->NewGlobalRef(env, sndPool);

		(*env)->DeleteLocalRef(env, amCls);
		(*env)->DeleteLocalRef(env, sndPoolCls);
		(*env)->DeleteLocalRef(env, sndPool);		
	}
}

static jmethodID gGetSndIdMthdId = NULL;

value ml_alsoundLoad(value path) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then again Sound.load");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jclass lmpCls = get_lmp_class();

	if (gGetSndIdMthdId == NULL) {
		gGetSndIdMthdId = (*env)->GetStaticMethodID(env, lmpCls, "getSoundId", "(Ljava/lang/String;Landroid/media/SoundPool;)I");
	}

	char* cpath = String_val(path);
	jstring jpath = (*env)->NewStringUTF(env, cpath);
	jint sndId = (*env)->CallStaticIntMethod(env, lmpCls, gGetSndIdMthdId, jpath, gSndPool);

	if (sndId < 0) {
		char mes[255];
		sprintf(mes, "cannot find %s when adding to sound pool", cpath);
		caml_failwith(mes);
	}

	(*env)->DeleteLocalRef(env, jpath);

	return Val_int(sndId);
}

static jmethodID gPlayMthdId = NULL;

value ml_alsoundPlay(value soundId, value vol, value loop) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#play");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gPlayMthdId == NULL) {
		gPlayMthdId = (*env)->GetMethodID(env, gSndPoolCls, "play", "(IFFIIF)I");
	}

	jdouble jvol = Double_val(vol);

	jint streamId = (*env)->CallIntMethod(env, gSndPool, gPlayMthdId, Int_val(soundId), jvol, jvol, 0, Bool_val(loop) ? -1 : 0, 1.0);

	return Val_int(streamId);
}

static jmethodID gPauseMthdId = NULL;

void ml_alsoundPause(value streamId) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#pause");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gPauseMthdId == NULL) {
		gPauseMthdId = (*env)->GetMethodID(env, gSndPoolCls, "pause", "(I)V");
	}
 
	(*env)->CallVoidMethod(env, gSndPool, gPauseMthdId, Int_val(streamId));
}

static jmethodID gStopMthdId = NULL;

void ml_alsoundStop(value streamId) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#stop");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gStopMthdId == NULL) {
		gStopMthdId = (*env)->GetMethodID(env, gSndPoolCls, "stop", "(I)V");
	}

	(*env)->CallVoidMethod(env, gSndPool, gStopMthdId, Int_val(streamId));

	PRINT_DEBUG("ml_alsoundStop call %d", Int_val(streamId));
}

static jmethodID gSetVolMthdId = NULL;

void ml_alsoundSetVolume(value streamId, value vol) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#setVolume");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gSetVolMthdId == NULL) {
		gSetVolMthdId = (*env)->GetMethodID(env, gSndPoolCls, "setVolume", "(IFF)V");
	}

	jdouble jvol = Double_val(vol);
	(*env)->CallVoidMethod(env, gSndPool, gSetVolMthdId, Int_val(streamId), jvol, jvol);
}

static jmethodID gSetLoopMthdId = NULL;

void ml_alsoundSetLoop(value streamId, value loop) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#setLoop");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gSetLoopMthdId == NULL) {
		gSetLoopMthdId = (*env)->GetMethodID(env, gSndPoolCls, "setLoop", "(II)V");
	}

	(*env)->CallVoidMethod(env, gSndPool, gSetLoopMthdId, Int_val(streamId), Bool_val(loop) ? -1 : 0);	
}

static jmethodID gAutoPause = NULL;
static jmethodID gAutoResume = NULL;

static jmethodID gLmpPauseAll = NULL;
static jmethodID gLmpResumeAll = NULL;

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnPause(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnPause call");

	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		if (gAutoPause == NULL) {
			gAutoPause = (*env)->GetMethodID(env, gSndPoolCls, "autoPause", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoPause);
	}

	jclass lmpCls = get_lmp_class();

	if (gLmpPauseAll == NULL) {
		gLmpPauseAll = (*env)->GetStaticMethodID(env, lmpCls, "pauseAll", "()V");
	}

	(*env)->CallStaticVoidMethod(env, lmpCls, gLmpPauseAll);

	static value dispatchBgHandler = 1;

	if (stage) {
		if (dispatchBgHandler == 1) dispatchBgHandler = caml_hash_variant("dispatchBackgroundEv");
		caml_callback2(caml_get_public_method(stage->stage, dispatchBgHandler), stage->stage, Val_unit);
	}	
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnResume(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnResume call");

	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
		
		if (gAutoResume == NULL) {
			gAutoResume = (*env)->GetMethodID(env, gSndPoolCls, "autoResume", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoResume);
	}

	jclass lmpCls = get_lmp_class();

	if (gLmpResumeAll == NULL) {
		gLmpResumeAll = (*env)->GetStaticMethodID(env, lmpCls, "resumeAll", "()V");
	}

	PRINT_DEBUG("resume ALL players");
	(*env)->CallStaticVoidMethod(env, lmpCls, gLmpResumeAll);

	if (surfaceDestroyed) {
		surfaceDestroyed = 0;
		onResume = 1;	
	} else {
		callDispatchFgHandler();
	}
}

void ml_openURL(value  url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	char* curl = String_val(url);
	jstring jurl = (*env)->NewStringUTF(env, curl);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "openURL", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jurl);

	(*env)->DeleteLocalRef(env, jurl);
}

void ml_addExceptionInfo (value info){
  	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cinfo = String_val(info);
	jstring jinfo = (*env)->NewStringUTF(env, cinfo);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlAddExceptionInfo", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jinfo);

	(*env)->DeleteLocalRef(env, jinfo);
}

void ml_setSupportEmail (value d){
  JNIEnv *env;
	DEBUG("DDD: set support email");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cd = String_val(d);
	jstring jd = (*env)->NewStringUTF(env, cd);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlSetSupportEmail", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jd);

	(*env)->DeleteLocalRef(env, jd);	
}

char* get_locale() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetLocale", "()Ljava/lang/String;");
	jstring locale = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env,locale,JNI_FALSE);
	char* retval = (char*)malloc(strlen(l) + 1);
	strcpy(retval, l);
	(*env)->ReleaseStringUTFChars(env, locale, l);
	(*env)->DeleteLocalRef(env, locale);

	return retval;		
}

value ml_getLocale () {
	char *c_locale = get_locale();
	value v_locale = caml_copy_string(c_locale);
	free(c_locale);
  	return v_locale;
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


static void mp_finalize(value vmp) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID releaseMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!releaseMid) {
		releaseMid = (*env)->GetMethodID(env, mpCls, "release", "()V"); 
	}

	(*env)->CallVoidMethod(env, jmp, releaseMid);
	(*env)->DeleteLocalRef(env, mpCls);
	(*env)->DeleteGlobalRef(env, jmp);
}

struct custom_operations mpOpts = {
	"pointer to MediaPlayer",
	mp_finalize,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default
};

value ml_avsound_create_player(value vpath) {
	CAMLparam1(vpath);
	CAMLlocal1(retval);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID createMpMid;
	jclass lmpCls = get_lmp_class();

	if (!createMpMid) createMpMid = (*env)->GetStaticMethodID(env, lmpCls, "createMediaPlayer", "(Ljava/lang/String;)Landroid/media/MediaPlayer;");

	const char* cpath = String_val(vpath);
	jstring jpath = (*env)->NewStringUTF(env, cpath);
	jobject mp = (*env)->CallStaticObjectMethod(env, lmpCls, createMpMid, jpath);

	if (!mp) {
		char mes[255];
		sprintf(mes, "cannot find %s when creating media player", cpath);		
		caml_failwith(mes);
	}

	jobject gmp = (*env)->NewGlobalRef(env, mp);

	(*env)->DeleteLocalRef(env, jpath);
	(*env)->DeleteLocalRef(env, mp);

	retval = caml_alloc_custom(&mpOpts, sizeof(jobject), 0, 1);
	*(jobject*)Data_custom_val(retval) = gmp;

	CAMLreturn(retval);
}

void testMethodId(JNIEnv *env, jclass cls, jmethodID *mid, char* methodName) {
	DEBUGF("testMethodId %s", methodName);
	if (!*mid) {
		DEBUGF("call %s", methodName);

		*mid = (*env)->GetMethodID(env, cls, methodName, "()V");
		//DEBUG("GetMethodID call");
	}
}

void ml_avsound_playback(value vmp, value vmethodName) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID pauseMid;
	static jmethodID stopMid;
	static jmethodID prepareMid;

	char* methodName = String_val(vmethodName);

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);
	jmethodID *mid;

	do {
		if (!strcmp(methodName, "stop")) {
			mid = &stopMid;
			break;
		}

		if (!strcmp(methodName, "pause")) {
			mid = &pauseMid;
			break;
		}

		if (!strcmp(methodName, "prepare")) {
			mid = &prepareMid;
			break;
		}
	} while(0);

	testMethodId(env, mpCls, mid, methodName);
	(*env)->CallVoidMethod(env, jmp, *mid);
	(*env)->DeleteLocalRef(env, mpCls);
}

void ml_avsound_set_loop(value vmp, value loop) {
	PRINT_DEBUG("!!!ml_avsound_set_loop call");

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID setLoopMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!setLoopMid) {
		setLoopMid = (*env)->GetMethodID(env, mpCls, "setLooping", "(Z)V");		
	}

	(*env)->CallVoidMethod(env, jmp, setLoopMid, Bool_val(loop));
	(*env)->DeleteLocalRef(env, mpCls);
}

void ml_avsound_set_volume(value vmp, value vol) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID setLoopMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!setLoopMid) {
		setLoopMid = (*env)->GetMethodID(env, mpCls, "setVolume", "(FF)V");
	}

	double cvol = Double_val(vol);
	(*env)->CallVoidMethod(env, jmp, setLoopMid, cvol, cvol);
	(*env)->DeleteLocalRef(env, mpCls);
}

value ml_avsound_is_playing(value vmp) {
	CAMLparam1(vmp);
	CAMLlocal1(retval);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID isPlayingMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!isPlayingMid) {
		isPlayingMid = (*env)->GetMethodID(env, mpCls, "isPlaying", "()Z");
	}

	//DEBUGF("ml_avsound_is_playing %s", (*env)->CallBooleanMethod(env, jmp, isPlayingMid) ? "true" : "false");

	retval = Val_bool((*env)->CallBooleanMethod(env, jmp, isPlayingMid));
	(*env)->DeleteLocalRef(env, mpCls);

	CAMLreturn(retval);
}

void ml_avsound_play(value vmp, value cb) {
	PRINT_DEBUG("ml_avsound_play tid: %d", gettid());

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID playMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!playMid) {
		playMid = (*env)->GetMethodID(env, mpCls, "start", "(I)V");
	}

	value *cbptr = malloc(sizeof(value));
	*cbptr = cb;
	caml_register_generational_global_root(cbptr);

	(*env)->CallVoidMethod(env, jmp, playMid, (jint)cbptr);
	(*env)->DeleteLocalRef(env, mpCls);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightMediaPlayer_00024CamlCallbackCompleteRunnable_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightMediaPlayer_00024CamlCallbackCompleteRunnable_run tid: %d", gettid());

	jclass runnableCls = (*env)->GetObjectClass(env, this);
	static jfieldID cbFid;

	if (!cbFid) {
		cbFid = (*env)->GetFieldID(env, runnableCls, "cb", "I");
	}

	value *cbptr = (value*)(*env)->GetIntField(env, this, cbFid);
	value cb = *cbptr;
	caml_callback(cb, Val_unit);
	caml_remove_generational_global_root(cbptr);

	(*env)->DeleteLocalRef(env, runnableCls);
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


void ml_tapjoy_init(value ml_appID,value ml_secretKey) {
	DEBUG("init tapjoy");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jstring appID = (*env)->NewStringUTF(env,String_val(ml_appID));
	jstring secretKey = (*env)->NewStringUTF(env,String_val(ml_secretKey));
	static jmethodID initTapjoyMethod = 0;
	if (initTapjoyMethod == 0) initTapjoyMethod = (*env)->GetMethodID(env,jViewCls,"initTapjoy","(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env,jView,initTapjoyMethod,appID,secretKey);
}

static jclass gTapjoyCls;
static jobject gTapjoy;

void getTapjoyJNI() {
	if (!gTapjoyCls) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jclass tapjoyCls = (*env)->FindClass(env, "com/tapjoy/TapjoyConnect");
		jmethodID mid = (*env)->GetStaticMethodID(env, tapjoyCls, "getTapjoyConnectInstance", "()Lcom/tapjoy/TapjoyConnect;");
		jobject tapjoy = (*env)->CallStaticObjectMethod(env, tapjoyCls, mid);

		gTapjoyCls = (*env)->NewGlobalRef(env, tapjoyCls);
		gTapjoy = (*env)->NewGlobalRef(env, tapjoy);

		(*env)->DeleteLocalRef(env, tapjoyCls);
		(*env)->DeleteLocalRef(env, tapjoy);
	}
}

void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jstring jcurrency = (*env)->NewStringUTF(env, String_val(currency));
	jboolean jshow_selector = Bool_val(show_selector);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffersWithCurrencyID", "(Ljava/lang/String;Z)V");
	}

	(*env)->CallVoidMethod(env, gTapjoy, mid, jcurrency, jshow_selector);
	(*env)->DeleteLocalRef(env, jcurrency);
}

void ml_tapjoy_show_offers() {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffers", "()V");
	}

	(*env)->CallVoidMethod(env, gTapjoy, mid);
}

void ml_tapjoy_set_user_id(value uid) {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "setUserID", "(Ljava/lang/String;)V");
	}

	jstring juid = (*env)->NewStringUTF(env, String_val(uid));
	(*env)->CallVoidMethod(env, gTapjoy, mid, juid);
	(*env)->DeleteLocalRef(env, juid);
}

static value device_id;

value ml_device_id(value unit) {
	/*DEBUGF("ML_DEVICE_ID");*/
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

static value udid;

value ml_getUDID(value unit) {
	DEBUGF("ML_UDID");
	if (!udid) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getUDID", "()Ljava/lang/String;");
		jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
		const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

		udid = caml_copy_string(cdev);
		caml_register_generational_global_root(&udid);

		(*env)->ReleaseStringUTFChars(env, jdev, cdev);
		(*env)->DeleteLocalRef(env, jdev);
	}

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

void ml_test_c_fun(value fun) {
	// caml_callback(fun,Val_unit);
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

void ml_showUrl(value v_url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "showUrl", "(Ljava/lang/String;)V");

	char* c_url = String_val(v_url);
	jstring j_url = (*env)->NewStringUTF(env, c_url);

	(*env)->CallVoidMethod(env, jView, mid, j_url);
	(*env)->DeleteLocalRef(env, j_url);
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

void ml_downloadExpansions() {
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

    static jmethodID mid = 0;
    if (!mid) mid = (*env)->GetMethodID(env, jViewCls, "downloadExpansions", "()V");

    (*env)->CallVoidMethod(env, jView, mid);	
}
