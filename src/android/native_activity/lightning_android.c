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

    jstring jcls_name = (*ENV)->NewStringUTF(ENV, ccls_name);
    jclass cls = FIND_CLASS(jcls_name);
    (*ENV)->DeleteLocalRef(ENV, cls);
    (*ENV)->DeleteLocalRef(ENV, jcls_name);

    int ret;
    k = kh_put(jclasses, classes, ccls_name, &ret);
    kh_val(classes, k) = (*ENV)->NewGlobalRef(ENV, cls);

    return kh_val(classes, k);
}

static jclass lightning_cls = NULL;

void lightning_init() {
    lightning_cls = lightning_find_class("ru/redspell/lightning/v2/Lightning");

    jfieldID fid = (*ENV)->GetStaticFieldID(ENV, lightning_cls, "activity", "Landroid/app/Activity;");
    (*ENV)->SetStaticObjectField(ENV, lightning_cls, fid, JAVA_ACTIVITY);
}

char *lightning_get_locale() {
	static char *retval = NULL;

    if (!retval) {
        jmethodID mid = (*ENV)->GetStaticMethodID(ENV, lightning_cls, "locale", "()Ljava/lang/String;");
        jstring jlocale = (*ENV)->CallStaticObjectMethod(ENV, lightning_cls, mid);
        const char* clocale = (*ENV)->GetStringUTFChars(ENV, jlocale, NULL);
        retval = malloc(strlen(clocale) + 1);
        strcpy(retval, clocale);

        (*ENV)->ReleaseStringUTFChars(ENV, jlocale, clocale);
        (*ENV)->DeleteLocalRef(ENV, jlocale);
    }

    return retval;
}

void lightning_runonmlthread(lightning_onmlthreadfunc_t func, void *data) {
    lightning_onmlthread_t *onmlthread = (lightning_onmlthread_t*)malloc(sizeof(lightning_onmlthread_t));
    onmlthread->func = func;
    onmlthread->data = data;

    struct android_app *app = engine.app;

    pthread_mutex_lock(&app->mutex);
    engine.data = onmlthread;
    android_app_write_cmd(app, LIGTNING_CMD_RUN_ON_ML_THREAD);
    pthread_mutex_unlock(&app->mutex);
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_v2_Lightning_activity(JNIEnv *env, jclass this) {
    return JAVA_ACTIVITY;
}