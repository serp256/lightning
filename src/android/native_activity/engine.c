#include "engine.h"
#include "mlwrapper_android.h"

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

    jstring _jcls_name = (*ML_ENV)->NewStringUTF(ML_ENV, "java/lang/String");
    jclass _cls = ML_FIND_CLASS(_jcls_name);
    PRINT_DEBUG("string cls %d", _cls);

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