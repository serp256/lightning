#ifndef ENGINE_H
#define ENGINE_H


#include <android/sensor.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <jni.h>
#include "android_native_app_glue.h"

struct saved_state {
    float angle;
    int32_t x;
    int32_t y;
};

struct engine {
    struct android_app* app;

    ASensorManager* sensorManager;
    const ASensor* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int32_t width;
    int32_t height;
    struct saved_state state;



    JNIEnv* env; // this env should be used only with native thread, not with main app thread. dont confuse this env with env from ANativeActivity struct.
    jclass activity_class;
    jobject class_loader;
    jmethodID load_class_mid;
    char* apk_path;
    char* main_exp_path;
    char* patch_exp_path;
    char* locale;

    void *data; // pointer for transfering custom data from main thread to caml thread
};

struct engine engine;
typedef struct engine* engine_t;

#define NATIVE_ACTIVITY engine.app->activity
#define JAVA_ACTIVITY NATIVE_ACTIVITY->clazz
#define VM NATIVE_ACTIVITY->vm
#define ENV engine.env
#define FIND_CLASS(name) (jclass)(*ENV)->CallObjectMethod(ENV, engine.class_loader, engine.load_class_mid, name);

void engine_init(struct android_app* app);
void engine_release();

#endif