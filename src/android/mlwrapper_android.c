#include "lightning_android.h"
#include "engine_android.h"
#include <caml/memory.h>
#include <android/window.h>

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

value ml_showUrl(value vurl) {
	CAMLparam1(vurl);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "showUrl", "(Ljava/lang/String;)V");

	jstring jurl;
	VAL_TO_JSTRING(vurl, jurl);

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jurl);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jurl);

	CAMLreturn(Val_unit);
}

value ml_getUDID() {
	CAMLparam0();
	CAMLlocal1(vudid);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getUDID", "()Ljava/lang/String;");

	jstring judid = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(judid, vudid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, judid);

	CAMLreturn(vudid);
}

value ml_getOldUDID() {
	CAMLparam0();
	CAMLlocal1(vudid);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getOldUDID", "()Ljava/lang/String;");

	jstring judid = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(judid, vudid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, judid);

	CAMLreturn(vudid);
}

value ml_malinfo(value p) {
	return caml_alloc_tuple(3);
}

value ml_openURL(value vurl) {
	jstring jurl;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "openURL", "(Ljava/lang/String;)V");

	VAL_TO_JSTRING(vurl, jurl);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jurl);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jurl);

	return Val_unit;
}

char *get_locale() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getLocale", "()Ljava/lang/String;");

	jstring jlocale = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	const char *clocale = (*ML_ENV)->GetStringUTFChars(ML_ENV, jlocale, JNI_FALSE);
	char *retval = (char*)malloc(strlen(clocale) + 1);
	strcpy(retval, clocale);
	(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jlocale, clocale);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jlocale);

	return retval;
}

value ml_getLocale () {
	char *clocale = get_locale();
	value vlocale = caml_copy_string(clocale);
	free(clocale);
	return vlocale;
}

value ml_getInternalStoragePath() {
	CAMLparam0();
	CAMLlocal1(vpath);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getInternalStoragePath", "()Ljava/lang/String;");

	jstring jpath = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jpath, vpath);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);

	CAMLreturn(vpath);
}

value ml_getStoragePath() {
	CAMLparam0();
	CAMLlocal1(vpath);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getStoragePath", "()Ljava/lang/String;");

	jstring jpath = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jpath, vpath);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);

	CAMLreturn(vpath);
}

value ml_getVersion() {
	CAMLparam0();
	CAMLlocal1(vver);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getVersion", "()Ljava/lang/String;");

	jstring jver = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jver, vver);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jver);

	CAMLreturn(vver);
}

value ml_androidScreen() {
	CAMLparam0();
	CAMLlocal1(vscreen);

	static jmethodID screen_mid = 0;
	static jmethodID density_mid = 0;

	if (!screen_mid) {
		screen_mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getScreen", "()I");
		density_mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getDensity", "()I");
	}

	jint jscreen = (*ML_ENV)->CallStaticIntMethod(ML_ENV, lightning_cls, screen_mid);
	jint jdensity = (*ML_ENV)->CallStaticIntMethod(ML_ENV, lightning_cls, density_mid);

	vscreen = caml_alloc_tuple(2);
	Store_field(vscreen, 0, Val_int(jscreen));
	Store_field(vscreen, 1, Val_int(jdensity));

	CAMLreturn(vscreen);
}

value ml_getDeviceType() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "isTablet", "()Z");

	return (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightning_cls, mid) == JNI_TRUE ? Val_true : Val_false;
}


value ml_platform() {
	CAMLparam0();
	CAMLlocal1(vplat);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "platform", "()Ljava/lang/String;");

	jstring jplat = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jplat, vplat);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jplat);

	CAMLreturn(vplat);
}

value ml_hwmodel() {
	CAMLparam0();
	CAMLlocal1(vmodel);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "hwmodel", "()Ljava/lang/String;");

	jstring jmodel = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jmodel, vmodel)
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jmodel);

	CAMLreturn(vmodel);
}

value ml_totalMemory() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "totalMemory", "()J");
	jlong jtotalmem = (*ML_ENV)->CallStaticLongMethod(ML_ENV, lightning_cls, mid);

	return Val_long(jtotalmem);
}

value ml_showNativeWait(value vmsg) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "showNativeWait", "(Ljava/lang/String;)V");

	jstring jmsg = NULL;
	if (Is_block(vmsg)) VAL_TO_JSTRING(Field(vmsg,0), jmsg);

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jmsg);
	if (jmsg) (*ML_ENV)->DeleteLocalRef(ML_ENV, jmsg);

	return Val_unit;
}

value ml_hideNativeWait(value p) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "hideNativeWait", "()V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);

	return Val_unit;
}

value ml_fire_lightning_event(value event_key) {
	return Val_unit;
}

value ml_str_to_lower(value vsrc) {
	CAMLparam1(vsrc);
	CAMLlocal1(vdst);

	static jmethodID mid = 0;
	if (!mid) {
		jclass cls = engine_find_class("java/lang/String");
		mid = (*ML_ENV)->GetMethodID(ML_ENV, cls, "toLowerCase", "()Ljava/lang/String;");
	}

	jstring jsrc;
	VAL_TO_JSTRING(vsrc, jsrc);
	jstring jdst = (*ML_ENV)->CallObjectMethod(ML_ENV, jsrc, mid);
	JSTRING_TO_VAL(jdst, vdst);

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jsrc);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jdst);

	CAMLreturn(vdst);
}

value ml_str_to_upper(value vsrc) {
	CAMLparam1(vsrc);
	CAMLlocal1(vdst);

	static jmethodID mid = 0;
	if (!mid) {
		jclass cls = engine_find_class("java/lang/String");
		mid = (*ML_ENV)->GetMethodID(ML_ENV, cls, "toUpperCase", "()Ljava/lang/String;");
	}

	jstring jsrc;
	VAL_TO_JSTRING(vsrc, jsrc);
	jstring jdst = (*ML_ENV)->CallObjectMethod(ML_ENV, jsrc, mid);
	JSTRING_TO_VAL(jdst, vdst);

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jsrc);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jdst);

	CAMLreturn(vdst);
}

value ml_silentUncaughtExceptionHandler(value vexn_json) {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "silentUncaughtException", "(Ljava/lang/String;)V");

	jstring jexn_json;
	VAL_TO_JSTRING(vexn_json, jexn_json);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jexn_json);

	return Val_unit;
}

value ml_uncaughtExceptionByMailSubjectAndBody(value unit) {
	CAMLparam0();
	CAMLlocal3(vsubject, vbody, vres);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "uncaughtExceptionByMailSubjectAndBody", "()[Ljava/lang/String;");

	jobjectArray jsubject_and_body = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	jstring jsubject = (*ML_ENV)->GetObjectArrayElement(ML_ENV, jsubject_and_body, 0);
	jstring jbody = (*ML_ENV)->GetObjectArrayElement(ML_ENV, jsubject_and_body, 1);
	JSTRING_TO_VAL(jsubject, vsubject);
	JSTRING_TO_VAL(jbody, vbody);
	vres = caml_alloc_tuple(2);
	Store_field(vres, 0, vsubject);
	Store_field(vres, 1, vbody);

	CAMLreturn(vres);
}

value ml_compression(value unit) {
	value res;

  const char *ext = (char*)glGetString(GL_EXTENSIONS);
	const char *ver = (char*)glGetString(GL_VERSION);

 	if (strstr(ver, "OpenGL ES 3.")) {
		res = Val_int(4);
  } else {
		if (strstr(ext, "GL_EXT_texture_compression_s3tc")) {
			res = Val_int(1);
		} else if (strstr(ext, "GL_IMG_texture_compression_pvrtc")) {
			res = Val_int(0);
		} else if (strstr(ext, "GL_AMD_compressed_ATC_texture") || strstr(ext, "GL_ATI_texture_compression_atitc")) {
			res = Val_int(2);
		} else if (strstr(ext, "GL_OES_compressed_ETC1_RGB8_texture")) {
			res = Val_int(3);
		};
  }

	return res;
}

static value *bg_delayed_callback = NULL;

value ml_setBackgroundDelayedCallback(value callback, value vdelay, value unit) {
	if (bg_delayed_callback) {
		caml_modify_generational_global_root(bg_delayed_callback, callback);
	} else {
		bg_delayed_callback = (value*)malloc(sizeof(value));
		*bg_delayed_callback = callback;
		caml_register_generational_global_root(bg_delayed_callback);
	}

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "setBackgroundCallbackDelay", "(J)V");

	long ldelay = Long_val(vdelay);
	if (ldelay <= 0) {
		caml_failwith("negative background callback delay restricted");
	}

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, (jlong)ldelay);

	return Val_unit;
}

value ml_resetBackgroundDelayedCallback(value unit) {
	if (bg_delayed_callback) {
		caml_remove_generational_global_root(bg_delayed_callback);
		free(bg_delayed_callback);
		bg_delayed_callback = NULL;
	}

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "resetBackgroundCallbackDelay", "()V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);

	return Val_unit;
}

void run_bg_delayed_callback(void *data) {
	PRINT_DEBUG("run_bg_delayed_callback");
	if (bg_delayed_callback) {
		caml_callback(*bg_delayed_callback, Val_unit);
	}
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_NativeActivity_00024TimerTask_run(JNIEnv *env, jclass this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_NativeActivity_00024TimerTask_run");
	RUN_ON_ML_THREAD(&run_bg_delayed_callback, NULL);
}

value ml_enableAwake(value unit) {
	ANativeActivity_setWindowFlags(NATIVE_ACTIVITY, AWINDOW_FLAG_KEEP_SCREEN_ON, 0);
	return Val_unit;
}

value ml_disableAwake(value unit) {
	ANativeActivity_setWindowFlags(NATIVE_ACTIVITY, 0, AWINDOW_FLAG_KEEP_SCREEN_ON);
	return Val_unit;
}

value ml_disableLog (value unit) {
	PRINT_DEBUG("ml_disableLog");
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "disableLog", "()V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);
	return Val_unit;
}
