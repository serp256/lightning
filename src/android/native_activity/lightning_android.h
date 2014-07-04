#ifndef LIGHTNING_ANDROID_H
#define LIGHTNING_ANDROID_H

#include <light_common.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

void	lightning_init			();
char*	lightning_get_locale	();
jclass	lightning_find_class	(const char *class_name); /* use this functions rather than FIND_CLASS macro from engine.h */

enum {
	LIGTNING_CMD_PAYMENT_SUCCESS = 100,
	LIGTNING_CMD_PAYMENT_FAIL
};

#endif