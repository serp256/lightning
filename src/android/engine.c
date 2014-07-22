#include "engine.h"
#include "mlwrapper_android.h"
#include "khash.h"

struct engine engine;

void engine_init(struct android_app* app) {
	memset(&engine, 0, sizeof(engine));
	engine.app = app;


	(*VM)->AttachCurrentThread(VM, &ML_ENV, NULL);
	jclass cls = (*ML_ENV)->GetObjectClass(ML_ENV, JAVA_ACTIVITY);
	engine.activity_class = (*ML_ENV)->NewGlobalRef(ML_ENV, cls);


	jmethodID mid = (*ML_ENV)->GetMethodID(ML_ENV, cls, "getPackageCodePath", "()Ljava/lang/String;");
	jstring japk_path = (*ML_ENV)->CallObjectMethod(ML_ENV, JAVA_ACTIVITY, mid);
	const char* capk_path = (*ML_ENV)->GetStringUTFChars(ML_ENV, japk_path, NULL);
	engine.apk_path = malloc(strlen(capk_path) + 1);
	strcpy(engine.apk_path, capk_path);

    /*
        Using class loader to obtain own java classes in native thread cause android jni doesnt provide
        any facility to obtain class references in any thread except main app thread. Even if AttachCurrentThread called.
    */
	mid = (*ML_ENV)->GetMethodID(ML_ENV, cls, "getClassLoader", "()Ljava/lang/ClassLoader;");
	jobject ldr = (*ML_ENV)->CallObjectMethod(ML_ENV, JAVA_ACTIVITY, mid);
	cls = (*ML_ENV)->GetObjectClass(ML_ENV, ldr);
	engine.class_loader = (*ML_ENV)->NewGlobalRef(ML_ENV, ldr);
	engine.load_class_mid = (*ML_ENV)->GetMethodID(ML_ENV, cls, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");

	(*ML_ENV)->ReleaseStringUTFChars(ML_ENV, japk_path, capk_path);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, japk_path);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, cls);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, ldr);
}

void engine_release() {
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, engine.activity_class);
	(*ML_ENV)->DeleteGlobalRef(ML_ENV, engine.class_loader);
	(*VM)->DetachCurrentThread(VM);

	free(engine.apk_path);
}

void engine_runonthread(uint8_t cmd, engine_runnablefunc_t func, void *data) {
    engine_runnable_t *onmlthread = (engine_runnable_t*)malloc(sizeof(engine_runnable_t));
    onmlthread->func = func;
    onmlthread->data = data;
    onmlthread->handled = 0;

    struct android_app *app = engine.app;

    pthread_mutex_lock(&app->mutex);
    engine.data = onmlthread;
    android_app_write_cmd(app, cmd);
    while (!onmlthread->handled) {
        pthread_cond_wait(&app->cond, &app->mutex);
    }    
    pthread_mutex_unlock(&app->mutex);
    free(onmlthread);
}

KHASH_MAP_INIT_STR(jclasses, jclass);
static kh_jclasses_t *classes = NULL;

jclass engine_find_class_with_env(JNIEnv *env, const char *ccls_name) {
    if (!classes) classes = kh_init_jclasses();

    khiter_t k = kh_get(jclasses, classes, ccls_name);
    if (k != kh_end(classes)) return kh_val(classes, k);

    jstring jcls_name = (*env)->NewStringUTF(env, ccls_name);
    jclass cls = ML_FIND_CLASS(jcls_name);
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, jcls_name);

    int ret;
    k = kh_put(jclasses, classes, ccls_name, &ret);
    kh_val(classes, k) = (*env)->NewGlobalRef(env, cls);

    return kh_val(classes, k);
}

jclass engine_find_class(const char *ccls_name) {
    return engine_find_class_with_env(ML_ENV, ccls_name);
}
