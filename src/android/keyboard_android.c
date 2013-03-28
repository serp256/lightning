#include "mlwrapper_android.h"

#define GET_LIGHT_KEYBOARD 															\
	JNIEnv *env;																	\
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);					\
	if (!kbrdCls) {																	\
		jclass cls = (*env)->FindClass(env,"ru/redspell/lightning/LightKeyboard"); 	\
		kbrdCls = (*env)->NewGlobalRef(env, cls); 									\
		(*env)->DeleteLocalRef(env, cls); 											\
	}																				\

#define CALLBACK(val, cvar)								\
	if (val != Val_int(0)) {							\
		value* cbptr = (value*)malloc(sizeof(value));	\
		*cbptr = Field(val, 0); 						\
		caml_register_generational_global_root(cbptr);	\
		cvar = (int)cbptr;								\
	}													\

static jclass kbrdCls = 0;
// static int kbrdVisible = 0;

void ml_keyboard(value visible, value size, value inittxt, value onhide, value onchange) {
	PRINT_DEBUG("ml_keyboard");

	// if (kbrdVisible) return;
	// kbrdVisible = 1;

	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, kbrdCls, "showKeyboard", "(ZIILjava/lang/String;II)V");

	int cvisible = visible == Val_int(0) ? 1 : Bool_val(Field(visible, 0));
	int cw = -1;
	int ch = -1;
	const char* cinittxt = inittxt == Val_int(0) ? "" : String_val(Field(inittxt, 0));
	int conhide = -1;
	int conchange = -1;

	CALLBACK(onhide, conhide);
	CALLBACK(onchange, conchange);

	if (Val_int(0) != size) {
		cw = Int_val(Field(Field(size, 0), 0));
		ch = Int_val(Field(Field(size, 0), 1));
	}

	jstring jinittxt = (*env)->NewStringUTF(env, cinittxt);
	(*env)->CallStaticVoidMethod(env, kbrdCls, mid, cvisible, cw, ch, jinittxt, conhide, conchange);
	(*env)->DeleteLocalRef(env, jinittxt);
}

void ml_keyboard_byte(value* argv, int argc) {
	PRINT_DEBUG("ml_keyboard_byte");
	ml_keyboard(argv[0], argv[1], argv[2], argv[3], argv[4]);
}

void ml_hidekeyboard() {
	PRINT_DEBUG("ml_hidekeyboard %d");

	// if (!kbrdVisible) return;
	// kbrdVisible = 0;

	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, kbrdCls, "hideKeyboard", "()V");

	(*env)->CallStaticVoidMethod(env, kbrdCls, mid);
}

void ml_copy(value txt) {
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, kbrdCls, "copyToClipboard", "(Ljava/lang/String;)V");

	const char* ctxt = String_val(txt);
	jstring jtxt = (*env)->NewStringUTF(env, ctxt);
	(*env)->CallStaticVoidMethod(env, kbrdCls, mid, jtxt);
	(*env)->DeleteLocalRef(env, jtxt);
}

value ml_paste() {
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*env)->GetStaticMethodID(env, kbrdCls, "pasteFromClipboard", "()Ljava/lang/String;");

	value retval;
	jstring jtxt = (*env)->CallStaticObjectMethod(env, kbrdCls, mid);

	if (jtxt) {
		const char* ctxt = (*env)->GetStringUTFChars(env, jtxt, JNI_FALSE);
		retval = caml_copy_string(ctxt);
		(*env)->ReleaseStringUTFChars(env, jtxt, ctxt);
	} else {
		retval = caml_copy_string("");
	}

	return retval;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightKeyboard_00024OnChangeRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID changeCbFid;
	static jfieldID txtFid;

	if (!changeCbFid) {
		jclass selfCls = (*env)->GetObjectClass(env, this);
		changeCbFid = (*env)->GetFieldID(env, selfCls, "cb", "I");
		txtFid = (*env)->GetFieldID(env, selfCls, "txt", "Ljava/lang/String;");
		(*env)->DeleteLocalRef(env, selfCls);
	}

	int ccb = (*env)->GetIntField(env, this, changeCbFid);

	if (ccb > -1) {
		jstring jtxt = (*env)->GetObjectField(env, this, txtFid);
		const char* ctxt = (*env)->GetStringUTFChars(env, jtxt, JNI_FALSE);

		caml_callback(*((value*)ccb), caml_copy_string(ctxt));
		(*env)->ReleaseStringUTFChars(env, jtxt, ctxt);
	}
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightKeyboard_00024OnHideRunnable_run(JNIEnv *env, jobject this) {
	// kbrdVisible = 0;

	static jfieldID changeCbFid;
	static jfieldID hideCbFid;
	static jfieldID txtFid;

	if (!changeCbFid) {
		jclass selfCls = (*env)->GetObjectClass(env, this);
		changeCbFid = (*env)->GetFieldID(env, selfCls, "changeCb", "I");
		hideCbFid = (*env)->GetFieldID(env, selfCls, "hideCb", "I");
		txtFid = (*env)->GetFieldID(env, selfCls, "txt", "Ljava/lang/String;");
		(*env)->DeleteLocalRef(env, selfCls);
	}

	int cchangeCb = (*env)->GetIntField(env, this, changeCbFid);
	int chideCb = (*env)->GetIntField(env, this, hideCbFid);

	if (cchangeCb > -1) {
		caml_remove_generational_global_root((value*)cchangeCb);
		free(cchangeCb);
	}

	if (chideCb > -1) {
		value* hideCb = (value*)chideCb;
		jstring jtxt = (*env)->GetObjectField(env, this, txtFid);
		const char* ctxt = (*env)->GetStringUTFChars(env, jtxt, JNI_FALSE);

		caml_callback(*hideCb, caml_copy_string(ctxt));
		caml_remove_generational_global_root(hideCb);
		free(hideCb);

		(*env)->ReleaseStringUTFChars(env, jtxt, ctxt);
	}
}