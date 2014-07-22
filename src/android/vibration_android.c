#include "lightning_android.h"
#include "engine_android.h"

value ml_vibration(value vtime) {
	int ctime = Int_val(vtime);

	static jmethodID mid = 0;
	if (!mid) mid = (*ML_ENV)->GetStaticMethodID(ML_ENV, lightning_cls, "vibrate", "(I)V");
	(*ML_ENV)->CallStaticVoidMethod(ML_ENV, lightning_cls, mid, (jint)ctime);

	return Val_unit;
}
