#include "engine.h"
#include "lightning_android.h"
#include "mlwrapper_android.h"

#include <pthread.h>

jclass lightning_cls;

void lightning_init() {
    lightning_cls = engine_find_class("ru/redspell/lightning/v2/Lightning");
    jmethodID mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "init", "()V");
    (*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid);
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
