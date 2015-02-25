#include "engine_android.h"
#include <android/keycodes.h>
#include <stdio.h>
#include <caml/memory.h>
#include <caml/alloc.h>

void gamecontroller_fpshandler() {
    PRINT_DEBUG("gamecontroller_fpshandler");
}

#define KEY_CALLBACK(key) static value *key##_callback = NULL; \
if (!key##_callback) { \
    const char *pattern = "Gamecontroller.Keys.%s"; \
    char func_name[strlen(pattern) - 2 + strlen(#key)]; \
    sprintf(func_name, pattern, #key); \
    key##_callback = caml_named_value(func_name); \
    caml_register_generational_global_root(key##_callback); \
} \
handled = caml_callback(*key##_callback, Val_unit) == Val_true;

#define CHECK_JOYSTICK(short, full, axis_x, axis_y) float short##_x = AMotionEvent_getAxisValue(event, axis_x, ptr_indx), \
    short##_y = AMotionEvent_getAxisValue(event, axis_y, ptr_indx); \
    static value *short##_callback = NULL; \
    if (short##_x != short##_val.x || short##_y != short##_val.y) { \
        if (!short##_callback) { \
            const char *pattern = "Gamecontroller.Joysticks.%s"; \
            char func_name[strlen(pattern) - 2 + strlen(#full)]; \
            sprintf(func_name, pattern, #full); \
            short##_callback = caml_named_value(func_name); \
            caml_register_generational_global_root(short##_callback); \
        } \
        arg = caml_alloc_tuple(2); \
        Store_field(arg, 0, caml_copy_double(short##_x)); \
        Store_field(arg, 1, caml_copy_double(short##_y)); \
        callback_res = caml_callback(*short##_callback, arg) == Val_true; \
        handled = handled || callback_res; \
        PRINT_DEBUG("done call %d", (int)short##_callback); \
        short##_val.x = short##_x; \
        short##_val.y = short##_y; \
    }

#define CHECK_TRIGGER(short, full, axis) float short##_newval = AMotionEvent_getAxisValue(event, axis, ptr_indx); \
    static value *short##_callback = NULL; \
    if (short##_val != short##_newval) { \
        if (!short##_callback) { \
            const char *pattern = "Gamecontroller.Triggers.%s"; \
            char func_name[strlen(pattern) - 2 + strlen(#full)]; \
            sprintf(func_name, pattern, #full); \
            short##_callback = caml_named_value(func_name); \
            caml_register_generational_global_root(short##_callback); \
        } \
        arg = caml_copy_double(short##_val); \
        callback_res = caml_callback(*short##_callback, arg) == Val_true; \
        handled = handled || callback_res; \
        short##_newval = short##_val; \
    }

typedef struct {
    float x, y;
} joystick_val_t;

uint8_t gamecontroller_inputhandler(AInputEvent *event) {
    CAMLparam0();
    CAMLlocal2(arg, callback_res);

    uint8_t handled = 0;

    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY && AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_UP) {
        handled = 1;

        switch (AKeyEvent_getKeyCode(event)) {
            case AKEYCODE_BACK: {
                KEY_CALLBACK(Back);
                break;
            }

            case AKEYCODE_MENU: {
                KEY_CALLBACK(Menu);
                break;
            }

            case AKEYCODE_BUTTON_A: {
                KEY_CALLBACK(A);
                break;
            }

            case AKEYCODE_BUTTON_B: {
                KEY_CALLBACK(B);
                break;
            }

            case AKEYCODE_BUTTON_X: {
                KEY_CALLBACK(X);
                break;
            }

            case AKEYCODE_BUTTON_Y: {
                KEY_CALLBACK(Y);
                break;
            }

            case AKEYCODE_BUTTON_THUMBL: {
                KEY_CALLBACK(LeftStick);
                break;
            }

            case AKEYCODE_BUTTON_THUMBR: {
                KEY_CALLBACK(RightStick);
                break;
            }

            case AKEYCODE_MEDIA_PLAY_PAUSE: {
               KEY_CALLBACK(PlayPause);
               break;
            }

            case AKEYCODE_MEDIA_REWIND: {
                KEY_CALLBACK(Rewind);
                break;
            }

            case AKEYCODE_MEDIA_FAST_FORWARD: {
                KEY_CALLBACK(FastForward);
                break;
            }

            case AKEYCODE_BUTTON_L1: {
                KEY_CALLBACK(LeftShoulder);
                break;
            }

            case AKEYCODE_BUTTON_R1: {
                KEY_CALLBACK(RightShoulder);
                break;
            }

            default:
                handled = 0;
        }
    } else if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        static joystick_val_t nav_val = { 0, 0 }, lstick_val = { 0, 0 }, rstick_val = { 0, 0 };
        static float ltrigger_val = 0, rtrigger_val = 0;

        int32_t action = AMotionEvent_getAction(event);
        size_t ptr_indx = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        action &= AMOTION_EVENT_ACTION_MASK;

        if (action == AMOTION_EVENT_ACTION_MOVE) {
            //PRINT_DEBUG("----------------");

            CHECK_JOYSTICK(nav, Navigation, AMOTION_EVENT_AXIS_HAT_X, AMOTION_EVENT_AXIS_HAT_Y);
            CHECK_JOYSTICK(lstick, Left, AMOTION_EVENT_AXIS_X, AMOTION_EVENT_AXIS_Y);
            CHECK_JOYSTICK(rstick, Right, AMOTION_EVENT_AXIS_Z, AMOTION_EVENT_AXIS_RZ);
            CHECK_TRIGGER(ltrigger, Left, AMOTION_EVENT_AXIS_BRAKE);
            CHECK_TRIGGER(rtrigger, Right, AMOTION_EVENT_AXIS_GAS);





            // PRINT_DEBUG("____________________________");
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_TILT %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_TILT, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_DISTANCE %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_DISTANCE, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_BRAKE %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_BRAKE, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_GAS %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_GAS, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_WHEEL %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_WHEEL, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_RUDDER %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RUDDER, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_THROTTLE %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_THROTTLE, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_RTRIGGER %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RTRIGGER, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_LTRIGGER %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_LTRIGGER, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_HAT_Y %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_HAT_Y, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_HAT_X %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_HAT_X, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_RZ %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RZ, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_RY %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RY, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_RX %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RX, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_Z %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Z, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_HSCROLL %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_HSCROLL, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_VSCROLL %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_VSCROLL, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_ORIENTATION %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_ORIENTATION, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_TOOL_MINOR %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_TOOL_MINOR, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_TOOL_MAJOR %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_TOOL_MAJOR, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_TOUCH_MINOR %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_TOUCH_MINOR, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_TOUCH_MAJOR %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_TOUCH_MAJOR, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_SIZE %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_SIZE, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_PRESSURE %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_PRESSURE, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_Y %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Y, ptr_indx));
            // PRINT_DEBUG("AMOTION_EVENT_AXIS_X %f", AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_X, ptr_indx));

        }
    }

    CAMLreturn(handled);
}

void gamecontroller_init() {
    dllist_engine_inputhandler_add(&engine.input_handlers, gamecontroller_inputhandler);
}
