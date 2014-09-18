#include "engine_android.h"
#include "khash.h"

struct engine engine;

void engine_init(struct android_app* app) {
	memset(&engine, 0, sizeof(engine));
    engine.app = app;
	engine.mlthread_id = gettid();


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

void engine_runonmlthread(engine_runnablefunc_t func, void *data) {
    if (engine.mlthread_id == gettid()) {
        func(data);
    } else {
        engine_runnable_t *runnable = (engine_runnable_t*)malloc(sizeof(engine_runnable_t));
        runnable->func = func;
        runnable->data = data;

        struct android_app *app = engine.app;
				android_app_write_cmd_with_data(app, ENGINE_CMD_RUN_ON_ML_THREAD, (void*)runnable);

        // pthread_mutex_lock(&app->mutex);
        // engine.data = runnable;
        // android_app_write_cmd(app, ENGINE_CMD_RUN_ON_ML_THREAD);
        // while (!runnable->handled) {
        //     pthread_cond_wait(&app->cond, &app->mutex);
        // }
        // pthread_mutex_unlock(&app->mutex);
        // free(runnable);
    }
}

void engine_runonuithread(engine_runnablefunc_t func, void *data) {
    engine_runnable_t *runnable = (engine_runnable_t*)malloc(sizeof(engine_runnable_t));
    runnable->func = func;
    runnable->data = data;

    static jmethodID mid = 0;
    if (!mid) mid = (*ML_ENV)->GetMethodID(ML_ENV, engine.activity_class, "runOnUiThread", "(I)V");
    (*ML_ENV)->CallVoidMethod(ML_ENV, JAVA_ACTIVITY, mid, (jint)runnable);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_NativeActivity_00024NativeRunnable_run(JNIEnv *env, jclass this, jint jrunnable) {
    engine_runnable_t *runnable = (engine_runnable_t*)jrunnable;
    (*runnable->func)(runnable->data);
    free(runnable);
}

KHASH_MAP_INIT_STR(jclasses, jclass);
static kh_jclasses_t *classes = NULL;

jclass engine_find_class_with_env(JNIEnv *env, const char *ccls_name) {
    PRINT_DEBUG("engine_find_class_with_env %s", ccls_name);

    if (!classes) classes = kh_init_jclasses();

    PRINT_DEBUG("1");

    khiter_t k = kh_get(jclasses, classes, ccls_name);
    if (k != kh_end(classes)) return kh_val(classes, k);

    PRINT_DEBUG("2");

    jstring jcls_name = (*env)->NewStringUTF(env, ccls_name);
    jclass cls = FIND_CLASS(env, jcls_name);
    (*env)->DeleteLocalRef(env, jcls_name);

    PRINT_DEBUG("3 %d", cls);

    int ret;
    k = kh_put(jclasses, classes, ccls_name, &ret);
    kh_val(classes, k) = (*env)->NewGlobalRef(env, cls);
    (*env)->DeleteLocalRef(env, cls);

    PRINT_DEBUG("done");

    return kh_val(classes, k);
}

jclass engine_find_class(const char *ccls_name) {
    return engine_find_class_with_env(ML_ENV, ccls_name);
}
