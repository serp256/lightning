#include "engine_android.h"
#include "lightning_android.h"
#include "main_android.h"
#include <android/keycodes.h>
#include <stdio.h>
#include <math.h>
#include <caml/memory.h>
#include <caml/alloc.h>

#define KEY_PHASE_DOWN 0x0
#define KEY_PHASE_UP 0x1

#define JOYSTICK_NONE 0x0
#define JOYSTICK_LEFT 0x1
#define JOYSTICK_RIGHT 0x2

#define FIX_JOYSTICK_AXIS(axis) if (fabs(axis) < 0.01) axis = 0;

typedef struct {
    float x, y;
    float inc_factor;
    float xinc, yinc;
    uint8_t joystick;
    dllist_engine_fpshandler_t *fps_handler;
} touches_joystick_t;

touches_joystick_t touches_joystick;
static value key_phase_up;
static value key_phase_down;

static value dpad_up;
static value dpad_center;
static value dpad_left;
static value dpad_right;
static value dpad_down;

void gamecontroller_firetouch(uint8_t phase) {
    CAMLparam0();
    CAMLlocal4(touches, touch, tx, ty);

    tx = caml_copy_double(touches_joystick.x);
    ty = caml_copy_double(touches_joystick.y);

    touch = caml_alloc_tuple(8);
    Store_field(touch, 0, caml_copy_int32(touches_joystick.joystick));
    Store_field(touch, 1, caml_copy_double(0.));
    Store_field(touch, 2, tx);
    Store_field(touch, 3, ty);
    Store_field(touch, 4, tx);
    Store_field(touch, 5, ty);
    Store_field(touch, 6, Val_int(1));
    Store_field(touch, 7, Val_int(phase));

    touches = caml_alloc_small(2, 0);
    Store_field(touches, 0, touch);
    Store_field(touches, 1, Val_none);

    mlstage_processTouches(engine.stage, touches);

    CAMLreturn0;
}

void gamecontroller_fpshandler() {
    touches_joystick.x += touches_joystick.inc_factor * touches_joystick.xinc;
    touches_joystick.y += touches_joystick.inc_factor * touches_joystick.yinc;
    gamecontroller_firetouch(1);
}

#define KEY_CALLBACK(key, phase) static value *key##_callback = NULL; \
static uint8_t key##_phase = KEY_PHASE_UP; \
if (key##_phase != phase) { \
    if (!key##_callback) { \
        const char *pattern = "Gamecontroller.Keys.%s"; \
        char func_name[strlen(pattern) - 2 + strlen(#key)]; \
        sprintf(func_name, pattern, #key); \
        key##_callback = caml_named_value(func_name); \
        caml_register_generational_global_root(key##_callback); \
    } \
    key##_phase = phase; \
    handled = caml_callback(*key##_callback, key##_phase == KEY_PHASE_UP ? key_phase_up : key_phase_down) == Val_true; \
} \

#define DPAD_CALLBACK(key, phase) static value *dpad##_callback = NULL; \
static uint8_t dpad##_phase = KEY_PHASE_UP; \
if (dpad##_phase != phase) { \
    if (!dpad##_callback) { \
        dpad##_callback = caml_named_value("Gamecontroller.Dpad"); \
        caml_register_generational_global_root(dpad##_callback); \
    } \
    dpad##_phase = phase; \
		arg = caml_alloc_tuple(2); \
		Store_field(arg, 0, key); \
		Store_field(arg, 1, dpad##_phase == KEY_PHASE_UP ? key_phase_up : key_phase_down); \
    handled = caml_callback(*dpad##_callback, arg ) == Val_true; \
} \

#define CHECK_JOYSTICK(short, full, axis_x, axis_y) float short##_x = AMotionEvent_getAxisValue(event, axis_x, ptr_indx), \
    short##_y = AMotionEvent_getAxisValue(event, axis_y, ptr_indx); \
    FIX_JOYSTICK_AXIS(short##_x); \
    FIX_JOYSTICK_AXIS(short##_y); \
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

		if (keyboard_is_visible () == 1) {
			handled = HANDLED_NOT_HANDLED;
		}
		else
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY) {
        value phase = AKeyEvent_getAction(event) == AKEY_EVENT_ACTION_DOWN ? KEY_PHASE_DOWN : KEY_PHASE_UP;

			PRINT_DEBUG ("key event");
        switch (AKeyEvent_getKeyCode(event)) {
            case AKEYCODE_BACK: {
                KEY_CALLBACK(Back, phase);
                break;
            }

            case AKEYCODE_MENU: {
                KEY_CALLBACK(Menu, phase);
                break;
            }

            case AKEYCODE_BUTTON_A: {
                KEY_CALLBACK(A, phase);
                break;
            }

            case AKEYCODE_BUTTON_B: {
                KEY_CALLBACK(B, phase);
                break;
            }

            case AKEYCODE_BUTTON_X: {
                KEY_CALLBACK(X, phase);
                break;
            }

            case AKEYCODE_BUTTON_Y: {
                KEY_CALLBACK(Y, phase);
                break;
            }

            case AKEYCODE_BUTTON_THUMBL: {
                KEY_CALLBACK(LeftStick, phase);
                break;
            }

            case AKEYCODE_BUTTON_THUMBR: {
                KEY_CALLBACK(RightStick, phase);
                break;
            }

            case AKEYCODE_MEDIA_PLAY_PAUSE: {
               KEY_CALLBACK(PlayPause, phase);
               break;
            }

            case AKEYCODE_MEDIA_REWIND: {
                KEY_CALLBACK(Rewind, phase);
                break;
            }

            case AKEYCODE_MEDIA_FAST_FORWARD: {
                KEY_CALLBACK(FastForward, phase);
                break;
            }

            case AKEYCODE_BUTTON_L1: {
                KEY_CALLBACK(LeftShoulder, phase);
                break;
            }

            case AKEYCODE_BUTTON_R1: {
                KEY_CALLBACK(RightShoulder, phase);
                break;
            }
						case AKEYCODE_DPAD_UP:{
                DPAD_CALLBACK(dpad_up, phase);
                break;
            }

						case AKEYCODE_DPAD_DOWN:{
                DPAD_CALLBACK(dpad_down, phase);
                break;
            }

						case AKEYCODE_DPAD_LEFT:{
                DPAD_CALLBACK(dpad_left, phase);
                break;
            }

						case AKEYCODE_DPAD_CENTER:{
                DPAD_CALLBACK(dpad_center, phase);
                break;
            }

            case AKEYCODE_DPAD_RIGHT:{
                DPAD_CALLBACK(dpad_right, phase);
                break;
            }
            default:
                handled = 0;
        }
    } else if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
			PRINT_DEBUG ("motion event %d", (keyboard_is_visible()));


			if (keyboard_is_visible () == 1) {
				handled = HANDLED_NOT_HANDLED;
			}
			else {
        static joystick_val_t nav_val = { 0, 0 }, lstick_val = { 0, 0 }, rstick_val = { 0, 0 };
        static float ltrigger_val = 0, rtrigger_val = 0;

        int32_t action = AMotionEvent_getAction(event);
        size_t ptr_indx = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        action &= AMOTION_EVENT_ACTION_MASK;

        if (action == AMOTION_EVENT_ACTION_MOVE) {
            CHECK_JOYSTICK(nav, Navigation, AMOTION_EVENT_AXIS_HAT_X, AMOTION_EVENT_AXIS_HAT_Y);

            if (touches_joystick.joystick == JOYSTICK_LEFT && touches_joystick.fps_handler) {
                touches_joystick.xinc = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_X, ptr_indx);
                touches_joystick.yinc = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Y, ptr_indx);
                FIX_JOYSTICK_AXIS(touches_joystick.xinc);
                FIX_JOYSTICK_AXIS(touches_joystick.yinc);
            } else {
                CHECK_JOYSTICK(lstick, Left, AMOTION_EVENT_AXIS_X, AMOTION_EVENT_AXIS_Y);
            }

            if (touches_joystick.joystick == JOYSTICK_RIGHT && touches_joystick.fps_handler) {
                touches_joystick.xinc = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_Z, ptr_indx);
                touches_joystick.yinc = AMotionEvent_getAxisValue(event, AMOTION_EVENT_AXIS_RZ, ptr_indx);
                FIX_JOYSTICK_AXIS(touches_joystick.xinc);
                FIX_JOYSTICK_AXIS(touches_joystick.yinc);
            } else {
                CHECK_JOYSTICK(rstick, Right, AMOTION_EVENT_AXIS_Z, AMOTION_EVENT_AXIS_RZ);
            }

            CHECK_TRIGGER(ltrigger, Left, AMOTION_EVENT_AXIS_BRAKE);
            CHECK_TRIGGER(rtrigger, Right, AMOTION_EVENT_AXIS_GAS);
        }
			}
    }

		PRINT_DEBUG ("is handled %d", handled);
    CAMLreturn(handled);
}

void gamecontroller_init() {
	PRINT_DEBUG("gamecontroller_init");
    touches_joystick.joystick = JOYSTICK_NONE;
    key_phase_up = hash_variant("up");
    key_phase_down = hash_variant("down");
    dpad_up = hash_variant("dpad_up");
    dpad_down = hash_variant("dpad_down");
    dpad_left = hash_variant("dpad_left");
    dpad_right = hash_variant("dpad_right");
    dpad_center = hash_variant("dpad_center");
    dllist_engine_inputhandler_add(&engine.input_handlers, gamecontroller_inputhandler);

}

value gamecontroller_bind_to_touches(value vinc_factor, value vpos, value vjoystick) {
    CAMLparam2(vpos, vjoystick);

    if (vjoystick == caml_hash_variant("none") && touches_joystick.joystick != JOYSTICK_NONE) {
        gamecontroller_firetouch(3);
        dllist_engine_fpshandler_remove(&engine.fps_handlers, touches_joystick.fps_handler);
        touches_joystick.fps_handler = NULL;
        touches_joystick.joystick = JOYSTICK_NONE;
    } else {
        if (vjoystick == caml_hash_variant("left")) touches_joystick.joystick = JOYSTICK_LEFT;
        if (vjoystick == caml_hash_variant("right")) touches_joystick.joystick = JOYSTICK_RIGHT;

        if (vpos == Val_none) {
            touches_joystick.x = 0;
            touches_joystick.y = 0;
        } else {
            touches_joystick.x = Double_val(Field(Field(vpos, 0), 0));
            touches_joystick.y = Double_val(Field(Field(vpos, 0), 1));
        }

        touches_joystick.xinc = 0;
        touches_joystick.yinc = 0;
        touches_joystick.inc_factor = Is_block(vinc_factor) ? Double_val(Field(vinc_factor, 0)) : 1;

        if (!touches_joystick.fps_handler) {
            gamecontroller_firetouch(0);
            touches_joystick.fps_handler = dllist_engine_fpshandler_add(&engine.fps_handlers, gamecontroller_fpshandler);
        }
    }

    CAMLreturn(Val_unit);
}
