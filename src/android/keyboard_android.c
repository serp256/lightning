#include "lightning_android.h"
#include "engine_android.h"

#define GET_LIGHT_KEYBOARD if (!cls) if (!cls) cls = engine_find_class("ru/redspell/lightning/keyboard/Keyboard");
#define CALLBACK(val, glob_val)								\
	if (val != Val_int(0)) {								\
		glob_val = (value*)malloc(sizeof(value));			\
		*glob_val = Field(val, 0); 							\
		caml_register_generational_global_root(glob_val);	\
	}

static jclass cls = 0;
value *onchage_callback = NULL;
value *onhide_callback = NULL;
// static int kbrdVisible = 0;

uint8_t keyboard_is_visible() {
	GET_LIGHT_KEYBOARD;
	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "visible", "()Z");
	return (*ML_ENV)->CallStaticBooleanMethod(ML_ENV, cls, mid);
}

value ml_keyboard(value vfilter, value visible, value size, value vinit_text, value onhide, value onchange) {
	PRINT_DEBUG("ml_keyboard");
	if (keyboard_is_visible()) return Val_unit;
	GET_LIGHT_KEYBOARD;

	PRINT_DEBUG("1");

	jstring jinit_text;
	jstring jfilter;
	OPTVAL_TO_JSTRING(vinit_text, jinit_text);
	OPTVAL_TO_JSTRING(vfilter, jfilter);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "show", "(Ljava/lang/String;Ljava/lang/String;)V");
	PRINT_DEBUG("ml_keyboard show mid %d", mid);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jinit_text, jfilter);

	CALLBACK(onhide, onhide_callback);
	CALLBACK(onchange, onchage_callback);

	return Val_unit;
}

value ml_keyboard_byte(value* argv, int argc) {
	PRINT_DEBUG("ml_keyboard_byte");
	return ml_keyboard(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

value ml_hidekeyboard() {
	if (!keyboard_is_visible()) return Val_unit;
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "hide", "()V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid);

	return Val_unit;
}

void keyboard_hide() {
	ml_hidekeyboard();
}

value ml_copy(value txt) {
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "copyToClipboard", "(Ljava/lang/String;)V");

	const char* ctxt = String_val(txt);
	jstring jtxt = (*ML_ENV)->NewStringUTF(ML_ENV, ctxt);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, jtxt);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jtxt);
	return Val_unit;
}

value ml_paste(value vcallback) {
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "pasteFromClipboard", "(I)V");
	value *callback;
	REG_CALLBACK(vcallback, callback);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, callback);

	return Val_unit;
}

void keyboard_onchange(void *data) {
	CAMLparam0();
	CAMLlocal1(vtext);

	jstring jtext = (jstring)data;

	if (onchage_callback) {
		JSTRING_TO_VAL(jtext, vtext);
		caml_callback(*onchage_callback, vtext);
	}

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jtext);
	CAMLreturn0;
}

void keyboard_onhide(void *data) {
	CAMLparam0();
	CAMLlocal1(vtext);

	jstring jtext = (jstring)data;

	if (onhide_callback) {
		JSTRING_TO_VAL(jtext, vtext);
		caml_callback(*onhide_callback, vtext);
		caml_remove_generational_global_root(onhide_callback);
		free(onhide_callback);
		onhide_callback = NULL;
	}

	if (onchage_callback) {
		caml_remove_generational_global_root(onchage_callback);
		free(onchage_callback);
		onchage_callback = NULL;
	}

	(*ML_ENV)->DeleteLocalRef(ML_ENV, jtext);
	CAMLreturn0;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_keyboard_Keyboard_onChange(JNIEnv *env, jclass this, jstring text) {
	RUN_ON_ML_THREAD(&keyboard_onchange, (*env)->NewGlobalRef(env, text));
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_keyboard_Keyboard_onHide(JNIEnv *env, jclass this, jstring text) {
	RUN_ON_ML_THREAD(&keyboard_onhide, (*env)->NewGlobalRef(env, text));
}

typedef struct {
	value *callback;
	jstring text;
} keyboard_paste_t;

void keyboard_paste(void *d) {
	keyboard_paste_t *data = (keyboard_paste_t*)d;
	value vtext;
	JSTRING_TO_VAL(data->text, vtext);
	RUN_CALLBACK(data->callback, vtext);
	FREE_CALLBACK(data->callback);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, data->text);
	free(data);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_keyboard_Keyboard_00024PasteRunnable_nativeRun(JNIEnv *env, jclass this, jint jcallback, jstring jtext) {
	keyboard_paste_t *data = (keyboard_paste_t*)malloc(sizeof(keyboard_paste_t));
	data->callback = (value*)jcallback;
	data->text = (*env)->NewGlobalRef(env, jtext);
	RUN_ON_ML_THREAD(&keyboard_paste, data);
}
