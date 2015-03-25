#include <errno.h>

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <android/log.h>
#include <android/asset_manager.h>
#include <android/window.h>

#include <sys/time.h>
#include <math.h>

#include "mobile_res.h"
#include "main_android.h"
#include "lightning_android.h"
#include "keyboard_android.h"
#include "sound_android.h"
#include "render_stub.h"
#include <kazmath/GL/matrix.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    return JNI_VERSION_1_6;
}

extern struct engine engine;

#define NEEDED_RED 5
#define NEEDED_GREEN 6
#define NEEDED_BLUE 5
#define NEEDED_ALPHA 0
#define NEEDED_DEPTH 0
#define NEEDED_STENCIL 0
#define CONFIGS_NUM 50

static int engine_init_display(engine_t engine) {
    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_ALPHA_SIZE, NEEDED_ALPHA,
            EGL_RED_SIZE, NEEDED_RED,
            EGL_GREEN_SIZE, NEEDED_GREEN,
            EGL_BLUE_SIZE, NEEDED_BLUE,
            EGL_DEPTH_SIZE, NEEDED_DEPTH,
            EGL_STENCIL_SIZE, NEEDED_STENCIL,
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
            EGL_NONE
    };

    EGLint w, h, format;
    EGLint numConfigs;
    EGLConfig configs[CONFIGS_NUM];
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;
    EGLDisplay display;

    if (engine->display == EGL_NO_DISPLAY) {
        display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        eglInitialize(display, 0, 0);
    } else {
        display = engine->display;
    }

    eglChooseConfig(display, attribs, configs, CONFIGS_NUM, &numConfigs);
    EGLint r, g, b, a, s, d;
    int i;
    for (i = 0; i < numConfigs; i++) {
      config = configs[i];

      eglGetConfigAttrib(display, config, EGL_ALPHA_SIZE, &a);
      eglGetConfigAttrib(display, config, EGL_BLUE_SIZE, &b);
      eglGetConfigAttrib(display, config, EGL_GREEN_SIZE, &g);
      eglGetConfigAttrib(display, config, EGL_RED_SIZE, &r);
      eglGetConfigAttrib(display, config, EGL_DEPTH_SIZE, &d);
      eglGetConfigAttrib(display, config, EGL_STENCIL_SIZE, &s);

      if (s >= NEEDED_STENCIL && d >= NEEDED_DEPTH) {
        if (r == NEEDED_RED && g == NEEDED_GREEN && b == NEEDED_BLUE && a == NEEDED_ALPHA) {
          break;
        }
      }
    }

    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);
    ANativeWindow_setBuffersGeometry(engine->app->window, 0, 0, format);

    surface = eglCreateWindowSurface(display, config, engine->app->window, NULL);

    EGLint const context_attrib_list[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
    context = engine->context == EGL_NO_CONTEXT
      ? eglCreateContext(display, config, NULL, context_attrib_list)
      : engine->context;

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
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

    if (!engine->stage) engine->stage = mlstage_create((float)w, (float)h);
    engine->animating = 1;

    return 0;
}

static double last_draw_time = 0.;

static void engine_draw_frame(engine_t engine) {
    //PRINT_DEBUG("engine_draw_frame");
    CAMLparam0();

    struct timeval now;
    if (!gettimeofday(&now, NULL)) {
        double _now = (double)now.tv_sec + (double)now.tv_usec / 1000000.;
        double diff = last_draw_time == 0. ? 0. : _now - last_draw_time;
        last_draw_time = _now;

        net_run();
        mlstage_advanceTime(engine->stage, diff);
        mlstage_preRender(engine->stage);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        restore_default_viewport();

        if (mlstage_render(engine->stage)) {
            eglSwapBuffers(engine->display, engine->surface);
        }
    }

    CAMLreturn0;
}

/**
 * Tear down the EGL context currently associated with the display.
 */
static void engine_term_display(engine_t engine) {
		PRINT_DEBUG("engine_term_display");


    if (engine->surface != EGL_NO_SURFACE) {
        eglMakeCurrent(engine->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

        if (engine->surface != EGL_NO_SURFACE) {
            eglDestroySurface(engine->display, engine->surface);
        }
    }

    PRINT_DEBUG("engine_term_display reseting animating flag");
    engine->animating = 0;
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
    //PRINT_DEBUG("engine_handle_input");

    CAMLparam0();
    CAMLlocal5(vtouches, vtouch, vtmp, vtx, vty);

    vtouches = Val_int(0);
    // engine_t engine = (engine_t)app->userData;

    //PRINT_DEBUG("AInputEvent_getType(event) %d, AINPUT_EVENT_TYPE_MOTION %d", AInputEvent_getType(event), AINPUT_EVENT_TYPE_MOTION);

    if (engine.input_handlers) {
        dllist_engine_inputhandler_t *el = engine.input_handlers;

        do {
            if ((*el->data)(event)) CAMLreturn(1);
            el = el->next;
        } while (el != engine.input_handlers);
    }


    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        if (engine.touches_disabled) {
            mlstage_cancelAllTouches(engine.stage);
            CAMLreturn(1);
        }

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

#define KEEP_TRACK(tid, tx, ty) { \
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
                            KEEP_TRACK(tid, tx, ty);
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
                KEEP_TRACK(tid, tx, ty);
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
                mlstage_cancelAllTouches(engine.stage);
                break;
        }

        //PRINT_DEBUG("process touches %d", process_touches);

        if (process_touches) {
            mlstage_processTouches(engine.stage, vtouches);
        }

#undef MAKE_TOUCH
#undef APPEND_TOUCH
#undef KEEP_TRACK
#undef LOSE_TRACK
#undef GET_TOUCH_PARAMS

        CAMLreturn(1);
    }/* else if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY) {
        int action = AKeyEvent_getAction(event);
        uint8_t handled = 0;

        LOGI("AINPUT_EVENT_TYPE_KEY, action %d", action);

        switch (action) {
          case AKEY_STATE_VIRTUAL:
          case AKEY_STATE_UP: {
              int key_code = AKeyEvent_getKeyCode(event);
              switch (key_code) {
                case AKEYCODE_BACK:
                  LOGI("AKEYCODE_BACK");
                  if (keyboard_is_visible()) {
                    keyboard_hide();
                    handled = 1;
                  }
                  break;

                default:
                  LOGI("key_code %d", key_code);
              }

              break;
            }
        }

        CAMLreturn(handled);
    }*/

    CAMLreturn(0);
}

static uint8_t foreground_called_on_resume = 1;

static void engine_handle_cmd(struct android_app* app, int32_t cmd, void *data) {
    //PRINT_DEBUG("engine_handle_cmd %d", cmd);
    engine_t engine = (engine_t)app->userData;
    static value bg_handler = 0, fg_handler = 0;

    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            engine->app->savedState = malloc(sizeof(struct saved_state));
            *((struct saved_state*)engine->app->savedState) = engine->state;
            engine->app->savedStateSize = sizeof(struct saved_state);
            break;
        case APP_CMD_INIT_WINDOW:
            if (engine->app->window != NULL) {
                engine_init_display(engine);
                if (!foreground_called_on_resume) {
                    sound_android_onforeground();
                    if (!fg_handler) fg_handler = caml_hash_variant("dispatchForegroundEv");
                    caml_callback2(caml_get_public_method(engine->stage->stage, fg_handler), engine->stage->stage, Val_unit);
                }
                engine_draw_frame(engine);
            }
            break;
        case APP_CMD_TERM_WINDOW:
            PRINT_DEBUG("APP_CMD_TERM_WINDOW");
            engine_term_display(engine);
            break;
        case APP_CMD_GAINED_FOCUS:
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_enableSensor(engine->sensorEventQueue, engine->accelerometerSensor);
                ASensorEventQueue_setEventRate(engine->sensorEventQueue, engine->accelerometerSensor, (1000L/60)*1000);
            }
            engine->animating = 1;
            engine_draw_frame(engine);
            break;
        case APP_CMD_LOST_FOCUS:
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_disableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
            }
            PRINT_DEBUG("APP_CMD_LOST_FOCUS reseting animating flag");
            engine->animating = 0;
            //engine_draw_frame(engine);
            break;

        case ENGINE_CMD_RUN_ON_ML_THREAD:
            {
                engine_runnable_t *runnable = (engine_runnable_t*)data;

                (*runnable->func)(runnable->data);
                free(runnable);

                // struct android_app *app = engine->app;
                // pthread_mutex_lock(&app->mutex);
                // engine_runnable_t *runnable = (engine_runnable_t*)engine->data;
                // (*runnable->func)(runnable->data);
                // runnable->handled = 1;
                // pthread_cond_broadcast(&app->cond);
                // pthread_mutex_unlock(&app->mutex);

                break;
            }

        case APP_CMD_PAUSE:
            PRINT_DEBUG("APP_CMD_PAUSE");

            foreground_called_on_resume = 0;
            if (engine->stage) {
                sound_android_onbackground();
                if (!bg_handler) bg_handler = caml_hash_variant("dispatchBackgroundEv");
                caml_callback2(caml_get_public_method(engine->stage->stage, bg_handler), engine->stage->stage, Val_unit);
            }

            break;

        case APP_CMD_RESUME:
            PRINT_DEBUG("APP_CMD_RESUME");

            if (engine->surface != EGL_NO_SURFACE && engine->stage) {
                foreground_called_on_resume = 1;
                sound_android_onforeground();
                if (!fg_handler) fg_handler = caml_hash_variant("dispatchForegroundEv");
                caml_callback2(caml_get_public_method(engine->stage->stage, fg_handler), engine->stage->stage, Val_unit);
            }

            break;

    }
}

void android_main(struct android_app* state) {
    app_dummy();
		/** kazmath do not use gl context as gl context, it is casted to void* and used as identifier to set of matrix stacks. we have no need for per context matrix sets.
		  * therefore doesn't matter what pass to this function.
		  */
		kmGLSetCurrentContext(state);
    touch_track = kh_init_tt();

    state->userData = &engine;
    state->onAppCmd = engine_handle_cmd;
    state->onInputEvent = engine_handle_input;

    engine_init(state);
    lightning_init();

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
    read_res_index(f, ass_offset, -1);

    fclose(f);
    close(indx_fd);

    if (state->savedState != NULL) {
        engine.state = *(struct saved_state*)state->savedState;
    }

    char *argv[] = {"android",NULL};
    PRINT_DEBUG("caml_startup...");
    caml_startup(argv);
    PRINT_DEBUG("caml_startup done");

    while (1) {
        int ident;
        int events;
        struct android_poll_source* source;

        //PRINT_DEBUG("ALooper_pollAll engine.animating %d", engine.animating);
        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, NULL, &events,
                (void**)&source)) >= 0) {
            //PRINT_DEBUG("inside poll all while");

            if (source != NULL) {
                source->process(state, source);
            }

            if (state->destroyRequested != 0) {
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.fps_handlers) {
            dllist_engine_fpshandler_t *el = engine.fps_handlers;

            do {
                (*el->data)();
                el = el->next;
            } while (el != engine.fps_handlers);
        }

        //PRINT_DEBUG("engine.animating %d", engine.animating);
        if (engine.animating) {
            engine_draw_frame(&engine);
        }

        //this is for galaxy note II: without sleep main java thread never
        usleep(150);
    }

    kh_destroy(tt, touch_track);
    engine_release();
}
