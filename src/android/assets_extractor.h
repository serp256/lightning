#include "unzip.h"
#include "light_common.h"
#include "mlwrapper_android.h"

int do_extract(const char* zip_path, const char* dst);
void ml_extractAssets(value cb);
/*JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExtractAssetsTask_extractAssets(JNIEnv *env, jobject this, jstring apkPath, jstring dst);
JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExtractAssetsTask_assetsExtracted(JNIEnv *env, jobject this, jint cbptr);*/