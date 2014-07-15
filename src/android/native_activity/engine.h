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

    void *data; // pointer to any user data. for example, for transfering custom data from main thread to ml thread
};

struct engine engine;
typedef struct engine* engine_t;

#define NATIVE_ACTIVITY engine.app->activity
#define JAVA_ACTIVITY NATIVE_ACTIVITY->clazz
#define VM NATIVE_ACTIVITY->vm

#define FIND_CLASS(env,name) (jclass)(*env)->CallObjectMethod(env, engine.class_loader, engine.load_class_mid, name);

#define ML_ENV engine.env
#define ML_FIND_CLASS(name) FIND_CLASS(ML_ENV, name)

#define MAIN_ENV NATIVE_ACTIVITY->env

void engine_init(struct android_app* app);
void engine_release();

#endif