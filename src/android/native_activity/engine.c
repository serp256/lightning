#include "engine.h"
#include "mlwrapper_android.h"

struct engine engine;

void engine_init(struct android_app* app) {
	memset(&engine, 0, sizeof(engine));
	engine.app = app;


	(*VM)->AttachCurrentThread(VM, &ENV, NULL);
	jclass cls = (*ENV)->GetObjectClass(ENV, JAVA_ACTIVITY);
	engine.activity_class = (*ENV)->NewGlobalRef(ENV, cls);


	jmethodID mid = (*ENV)->GetMethodID(ENV, cls, "getPackageCodePath", "()Ljava/lang/String;");
	jstring japk_path = (*ENV)->CallObjectMethod(ENV, JAVA_ACTIVITY, mid);
	const char* capk_path = (*ENV)->GetStringUTFChars(ENV, japk_path, NULL);
	engine.apk_path = malloc(strlen(capk_path) + 1);
	strcpy(engine.apk_path, capk_path);

    /*
        Using class loader to obtain own java classes in native thread cause android jni doesnt provide
        any facility to obtain class references in any thread except main app thread. Even if AttachCurrentThread called.
    */
	mid = (*ENV)->GetMethodID(ENV, cls, "getClassLoader", "()Ljava/lang/ClassLoader;");
	jobject ldr = (*ENV)->CallObjectMethod(ENV, JAVA_ACTIVITY, mid);
	cls = (*ENV)->GetObjectClass(ENV, ldr);
	engine.class_loader = (*ENV)->NewGlobalRef(ENV, ldr);
	engine.load_class_mid = (*ENV)->GetMethodID(ENV, cls, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");

    jstring _jcls_name = (*ENV)->NewStringUTF(ENV, "java/lang/String");
    jclass _cls = FIND_CLASS(_jcls_name);
    PRINT_DEBUG("string cls %d", _cls);

	(*ENV)->ReleaseStringUTFChars(ENV, japk_path, capk_path);
	(*ENV)->DeleteLocalRef(ENV, japk_path);
	(*ENV)->DeleteLocalRef(ENV, cls);
	(*ENV)->DeleteLocalRef(ENV, ldr);
}

void engine_release() {
	(*ENV)->DeleteGlobalRef(ENV, engine.activity_class);
	(*ENV)->DeleteGlobalRef(ENV, engine.class_loader);
	(*VM)->DetachCurrentThread(VM);

	free(engine.apk_path);
}