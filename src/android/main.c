#include <errno.h>

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <android/log.h>
#include <android/asset_manager.h>
#include <android/window.h>
 
#include <sys/time.h>
#include <math.h>

#include "mlwrapper_android.h"
#include "mobile_res.h"
#include "main.h"
#include "helper.h"

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

extern struct engine engine;

static int engine_init_display(engine_t engine) {
    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    };
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    eglInitialize(display, 0, 0);
    eglChooseConfig(display, attribs, &config, 1, &numConfigs);
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(engine->app->window, 0, 0, format);

    EGLint const context_attrib_list[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    surface = eglCreateWindowSurface(display, config, engine->app->window, NULL);
    context = eglCreateContext(display, config, NULL, context_attrib_list);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    engine->display = display;
    engine->context = context;
    engine->surface = surface;
    engine->width = w;
    engine->height = h;
    engine->state.angle = 0;

    stage = mlstage_create((float)w, (float)h);
    engine->animating = 1;

    return 0;
}

static struct timeval last_draw_time;

static void engine_draw_frame(engine_t engine) {
    CAMLparam0();

    struct timeval now;
    if (!gettimeofday(&now, NULL)) {
        double diff = (double)(now.tv_usec - last_draw_time.tv_usec) / 1000000.;
        last_draw_time = now;

        net_run();
        mlstage_advanceTime(stage, diff);
        mlstage_preRender(stage);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        restore_default_viewport();

        if (mlstage_render(stage)) {
            eglSwapBuffers(engine->display, engine->surface);    
        }
    }

    CAMLreturn0;
}

/**
 * Tear down the EGL context currently associated with the display.
 */
static void engine_term_display(engine_t engine) {
    if (engine->display != EGL_NO_DISPLAY) {
        eglMakeCurrent(engine->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (engine->context != EGL_NO_CONTEXT) {
            eglDestroyContext(engine->display, engine->context);
        }
        if (engine->surface != EGL_NO_SURFACE) {
            eglDestroySurface(engine->display, engine->surface);
        }
        eglTerminate(engine->display);
    }
    engine->animating = 0;
    engine->display = EGL_NO_DISPLAY;
    engine->context = EGL_NO_CONTEXT;
    engine->surface = EGL_NO_SURFACE;
}

typedef struct {
    float x;
    float y;
} touch_track_t;

// tt means touch track
KHASH_MAP_INIT_INT(tt, touch_track_t*);
kh_tt_t* touch_track = NULL;

static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
    CAMLparam0();
    CAMLlocal5(vtouches, vtouch, vtmp, vtx, vty);

    vtouches = Val_int(0);
    engine_t engine = (engine_t)app->userData;

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
#define MAKE_TOUCH(touch, id, x, y, phase) touch = caml_alloc_tuple(8); \
    vtx = caml_copy_double(x); \
    vty = caml_copy_double(y); \
    Store_field(touch,0,caml_copy_int32(id + 1)); \
    Store_field(touch,1,caml_copy_double(0.)); \
    Store_field(touch,2,vtx); \
    Store_field(touch,3,vty); \
    Store_field(touch,4,vtx); \
    Store_field(touch,5,vty); \
    Store_field(touch,6,Val_int(1)); \
    Store_field(touch,7,Val_int(phase));

#define APPEND_TOUCH vtmp = vtouches; \
    vtouches = caml_alloc_small(2,0); \
    Store_field(vtouches, 0, vtouch); \
    Store_field(vtouches, 1, vtmp);
        int32_t action = AMotionEvent_getAction(event);
        size_t ptr_indx = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        action &= AMOTION_EVENT_ACTION_MASK;

#define GET_TOUCH_PARAMS tid = AMotionEvent_getPointerId(event, ptr_indx); \
    tx = AMotionEvent_getX(event, ptr_indx); \
    ty = AMotionEvent_getY(event, ptr_indx);

#define KEEP_TACK(tid, tx, ty) { \
        k = kh_get(tt, touch_track, tid); \
        touch_track_t* touch; \
        if (k != kh_end(touch_track)) { \
            touch = kh_val(touch_track, k); \
        } else { \
            touch = (touch_track_t*)malloc(sizeof(touch_track_t)); \
            int ret; \
            k = kh_put(tt, touch_track, tid, &ret); \
            kh_val(touch_track, k) = touch; \
        } \
        touch->x = tx; \
        touch->y = ty; \
    }

#define LOSE_TRACK(id) k = kh_get(tt, touch_track, id); \
    if (k != kh_end(touch_track)) { \
        free(kh_val(touch_track, k)); \
        kh_del(tt, touch_track, k); \
    }

#define GET_TRACK(id, track) k = kh_get(tt, touch_track, id); \
    track = k != kh_end(touch_track) ? kh_val(touch_track, k) : NULL;

        int32_t tid;
        float tx, ty;
        khiter_t k;
        int8_t process_touches = 0;

        switch (action) {
            case AMOTION_EVENT_ACTION_MOVE: {
                size_t ptr_cnt = AMotionEvent_getPointerCount(event);
                touch_track_t* touch;

                for (ptr_indx = 0; ptr_indx < ptr_cnt; ptr_indx++) {
                    GET_TOUCH_PARAMS;
                    GET_TRACK(tid, touch);

                    if (!touch || fabs(touch->x - tx) > 10 || fabs(touch->y - ty) > 10) {
                        if (!touch) {
                            KEEP_TACK(tid, tx, ty);
                        } else {
                            touch->x = tx;
                            touch->y = ty;
                        }

                        process_touches = 1;
                        MAKE_TOUCH(vtouch, tid, tx, ty, 1);
                    } else {
                        MAKE_TOUCH(vtouch, tid, tx, ty, 2);
                    }

                    APPEND_TOUCH;
                }

                break;
            }

            case AMOTION_EVENT_ACTION_DOWN:
            case AMOTION_EVENT_ACTION_POINTER_DOWN:
                process_touches = 1;
                if (action == AMOTION_EVENT_ACTION_DOWN) ptr_indx = 0;

                GET_TOUCH_PARAMS;
                KEEP_TACK(tid, tx, ty);
                MAKE_TOUCH(vtouch, tid, tx, ty, 0);
                APPEND_TOUCH;

                break;

            case AMOTION_EVENT_ACTION_UP:
            case AMOTION_EVENT_ACTION_POINTER_UP:
                process_touches = 1;
                if (action == AMOTION_EVENT_ACTION_UP) ptr_indx = 0;

                GET_TOUCH_PARAMS;
                LOSE_TRACK(tid);
                MAKE_TOUCH(vtouch, tid, tx, ty, 3);
                APPEND_TOUCH;

                break;

            case AMOTION_EVENT_ACTION_CANCEL:
                mlstage_cancelAllTouches(stage);
                break;
        }

        if (process_touches) {
            mlstage_processTouches(stage, vtouches);
        }

#undef MAKE_TOUCH
#undef APPEND_TOUCH
#undef KEEP_TACK
#undef LOSE_TACK
#undef GET_TOUCH_PARAMS

        CAMLreturn(1);
    }

    CAMLreturn(0);
}

static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
    engine_t engine = (engine_t)app->userData;
    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            engine->app->savedState = malloc(sizeof(struct saved_state));
            *((struct saved_state*)engine->app->savedState) = engine->state;
            engine->app->savedStateSize = sizeof(struct saved_state);
            break;
        case APP_CMD_INIT_WINDOW:
            if (engine->app->window != NULL) {
                engine_init_display(engine);
                engine_draw_frame(engine);
            }
            break;
        case APP_CMD_TERM_WINDOW:
            engine_term_display(engine);
            break;
        case APP_CMD_GAINED_FOCUS:
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_enableSensor(engine->sensorEventQueue, engine->accelerometerSensor);
                ASensorEventQueue_setEventRate(engine->sensorEventQueue, engine->accelerometerSensor, (1000L/60)*1000);
            }
            break;
        case APP_CMD_LOST_FOCUS:
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_disableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
            }
            engine->animating = 0;
            engine_draw_frame(engine);
            break;
    }
}

void android_main(struct android_app* state) {
    app_dummy();

    touch_track = kh_init_tt();

    state->userData = &engine;
    state->onAppCmd = engine_handle_cmd;
    state->onInputEvent = engine_handle_input;
    
    engine_init(state);
    helper_init();

    AAssetManager* mngr = state->activity->assetManager;
    AAsset* ass = AAssetManager_open(mngr, "assets", AASSET_MODE_UNKNOWN);
    AAsset* indx = AAssetManager_open(mngr, "index", AASSET_MODE_UNKNOWN);
    off_t ass_offset, ass_len, indx_offset, indx_len;

    int ass_fd = AAsset_openFileDescriptor(ass, &ass_offset, &ass_len);
    int indx_fd = AAsset_openFileDescriptor(indx, &indx_offset, &indx_len);

    AAsset_close(ass);
    AAsset_close(indx);

    FILE* f = fdopen(ass_fd, "r");
    fseek(f, indx_offset, SEEK_SET);
    char* err = read_res_index(f, ass_offset, -1);
    
    fclose(f);
    close(indx_fd);

    ANativeActivity_setWindowFlags(state->activity, AWINDOW_FLAG_FULLSCREEN, 0);

    if (state->savedState != NULL) {
        engine.state = *(struct saved_state*)state->savedState;
    }

    char *argv[] = {"android",NULL};
    caml_startup(argv);

    while (1) {
        int ident;
        int events;
        struct android_poll_source* source;

        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, NULL, &events,
                (void**)&source)) >= 0) {

            if (source != NULL) {
                source->process(state, source);
            }

            if (state->destroyRequested != 0) {
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.animating) {
            engine_draw_frame(&engine);
        }
    }

    kh_destroy(tt, touch_track);
    engine_release();
}
