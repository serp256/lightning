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

value ml_keyboard(value visible, value size, value inittxt, value onhide, value onchange) {
	PRINT_DEBUG("ml_keyboard");

	// if (kbrdVisible) return;
	// kbrdVisible = 1;

	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "showKeyboard", "(ZIILjava/lang/String;)V");

	int cvisible = visible == Val_int(0) ? 1 : Bool_val(Field(visible, 0));
	int cw = -1;
	int ch = -1;
	const char* cinittxt = inittxt == Val_int(0) ? "" : String_val(Field(inittxt, 0));

	CALLBACK(onhide, onhide_callback);
	CALLBACK(onchange, onchage_callback);

	if (Val_int(0) != size) {
		cw = Int_val(Field(Field(size, 0), 0));
		ch = Int_val(Field(Field(size, 0), 1));
	}

	jstring jinittxt = (*ML_ENV)->NewStringUTF(ML_ENV, cinittxt);
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid, cvisible, cw, ch, jinittxt);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, jinittxt);

	return Val_unit;
}

value ml_keyboard_byte(value* argv, int argc) {
	PRINT_DEBUG("ml_keyboard_byte");
	return ml_keyboard(argv[0], argv[1], argv[2], argv[3], argv[4]);
}

value ml_hidekeyboard() {
	PRINT_DEBUG("ml_hidekeyboard %d");

	// if (!kbrdVisible) return;
	// kbrdVisible = 0;

	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "hideKeyboard", "()V");

	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, cls, mid);

	return Val_unit;
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

value ml_paste() {
	GET_LIGHT_KEYBOARD;

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, cls, "pasteFromClipboard", "()Ljava/lang/String;");

	value retval;
	jstring jtxt = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, cls, mid);

	if (jtxt) {
		const char* ctxt = (*ML_ENV)->GetStringUTFChars(ML_ENV, jtxt, JNI_FALSE);
		retval = caml_copy_string(ctxt);
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jtxt, ctxt);
	} else {
		retval = caml_copy_string("");
	}

	return retval;
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
