#include "lightning_android.h"
#include "engine.h"

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

value ml_addExceptionInfo (value vinf){
	jstring jinf;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "addExceptionInfo", "(Ljava/lang/String;)V");

	VAL_TO_JSTRING(vinf, jinf);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jinf);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jinf);

	return Val_unit;
}

value ml_setSupportEmail(value vmail) {
	jstring jmail;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "setSupportEmail", "(Ljava/lang/String;)V");

	VAL_TO_JSTRING(vmail, jmail);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, jmail);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jmail);

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
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getInternalStoragePath", "()Ljava/lang/String;");

	value vpath;
	jstring jpath = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jpath, vpath);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);

	return vpath;
}

value ml_getStoragePath() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getStoragePath", "()Ljava/lang/String;");

	value vpath;
	jstring jpath = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jpath, vpath);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jpath);

	return vpath;
}

value ml_getVersion() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getVersion", "()Ljava/lang/String;");

	value vver;
	jstring jver = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jver, vver);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jver);

	return vver;
}

value ml_androidScreen() {
	static jmethodID screen_mid = 0;
	static jmethodID density_mid = 0;

	if (!screen_mid) {
		screen_mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getScreen", "()I");
		density_mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "getDensity", "()I");
	}

	jint jscreen = (*ML_ENV)->CallStaticIntMethod(ML_ENV, lightning_cls, screen_mid);
	jint jdensity = (*ML_ENV)->CallStaticIntMethod(ML_ENV, lightning_cls, density_mid);
	
	value vscreen = caml_alloc_tuple(2);
	Store_field(vscreen, 0, Val_int(jscreen));
	Store_field(vscreen, 1, Val_int(jdensity));

	return vscreen;
}

value ml_getDeviceType() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "isTablet", "()Z");

	return (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, lightning_cls, mid) == JNI_TRUE ? Val_true : Val_false;
}


value ml_platform() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "platform", "()Ljava/lang/String;");

	value vplat;
	jstring jplat = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jplat, vplat);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jplat);

	return vplat;
}

value ml_hwmodel() {
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "hwmodel", "()Ljava/lang/String;");

	value vmodel;
	jstring jmodel = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
	JSTRING_TO_VAL(jmodel, vmodel)
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jmodel);

	return vmodel;
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
