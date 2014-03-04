#include <android/sensor.h>
#include <EGL/egl.h>
#include <GLES/gl.h>
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

    char* locale;
};

extern struct engine engine;
typedef struct engine* engine_t;

#define ACTIVITY engine.app->activity
#define VM ACTIVITY->vm
#define ENV ACTIVITY->env

void android_main(struct android_app* state);