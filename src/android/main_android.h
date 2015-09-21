#ifndef MAIN_H
#define MAIN_H

#include "engine_android.h"

#define NOT_HANDLED 0
#define HANDLED 1
// need to handle controller joysticks movement for tv keyboard
#define HANDLED_NOT_HANDLED 2
void android_main(struct android_app* state);

#endif
