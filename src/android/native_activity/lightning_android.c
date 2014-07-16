#include "engine.h"
#include "lightning_android.h"
#include "mlwrapper_android.h"

#include <pthread.h>

jclass lightning_cls;

void lightning_init() {
    PRINT_DEBUG("1");

    lightning_cls = engine_find_class("ru/redspell/lightning/v2/Lightning");
    PRINT_DEBUG("2 %d", lightning_cls);
    jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "init", "()V");
    PRINT_DEBUG("3");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);
    PRINT_DEBUG("4");
}

char *lightning_get_locale() {
	static char *retval = NULL;

    if (!retval) {
        jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "locale", "()Ljava/lang/String;");
        jstring jlocale = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, lightning_cls, mid);
        const char* clocale = (*ML_ENV)->GetStringUTFChars(ML_ENV, jlocale, NULL);
        retval = malloc(strlen(clocale) + 1);
        strcpy(retval, clocale);

        (*ML_ENV)->ReleaseStringUTFChars(ML_ENV, jlocale, clocale);
        (*ML_ENV)->DeleteLocalRef(ML_ENV, jlocale);
    }

    return retval;
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *env, jclass this) {
    return JAVA_ACTIVITY;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Lightning_disableTouches(JNIEnv *env, jclass this) {
    engine.touches_disabled = 1;
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_v2_Lightning_enableTouches(JNIEnv *env, jclass this) {
    engine.touches_disabled = 0;
}
