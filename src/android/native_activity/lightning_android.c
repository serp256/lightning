#include "engine.h"
#include "lightning_android.h"
#include "mlwrapper_android.h"
#include "khash.h"

#include <pthread.h>

KHASH_MAP_INIT_STR(jclasses, jclass);
static kh_jclasses_t *classes = NULL;

jclass lightning_find_class(const char *ccls_name) {
    if (!classes) classes = kh_init_jclasses();

    khiter_t k = kh_get(jclasses, classes, ccls_name);
    if (k != kh_end(classes)) return kh_val(classes, k);

    jstring jcls_name = (*ML_ENV)->NewStringUTF(ML_ENV, ccls_name);
    jclass cls = ML_FIND_CLASS(jcls_name);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, cls);
    (*ML_ENV)->DeleteLocalRef(ML_ENV, jcls_name);

    int ret;
    k = kh_put(jclasses, classes, ccls_name, &ret);
    kh_val(classes, k) = (*ML_ENV)->NewGlobalRef(ML_ENV, cls);

    return kh_val(classes, k);
}

static jclass lightning_cls = NULL;

void lightning_init() {
    lightning_cls = lightning_find_class("ru/redspell/lightning/v2/Lightning");
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

void lightning_runonthread(uint8_t cmd, lightning_runnablefunc_t func, void *data) {
    lightning_runnable_t *onmlthread = (lightning_runnable_t*)malloc(sizeof(lightning_runnable_t));
    onmlthread->func = func;
    onmlthread->data = data;

    struct android_app *app = engine.app;

    pthread_mutex_lock(&app->mutex);
    engine.data = onmlthread;
    android_app_write_cmd(app, cmd);
    pthread_mutex_unlock(&app->mutex);
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *env, jclass this) {
    return JAVA_ACTIVITY;
}
