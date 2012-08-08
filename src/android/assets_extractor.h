#include "unzip.h"
#include "light_common.h"
#include "mlwrapper_android.h"

void ml_miniunz(value vzipPath, value vdstPath);
JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024UnzipCallbackRunnable_run(JNIEnv *env, jobject this);
value ml_apkPath();
value ml_externalStoragePath();