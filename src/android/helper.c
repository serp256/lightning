#include "engine.h"
#include "helper.h"
#include "mlwrapper_android.h"

static jclass helper_cls;

void helper_init(jobject activity) {
    jstring cls_name = (*ENV)->NewStringUTF(ENV, "ru/redspell/lightning/LightNativeActivityHelper");
    jclass cls = FIND_CLASS(cls_name);
    helper_cls = (*ENV)->NewGlobalRef(ENV, cls);

    jfieldID fid = (*ENV)->GetStaticFieldID(ENV, helper_cls, "activity", "Landroid/app/Activity;");
    (*ENV)->SetStaticObjectField(ENV, helper_cls, fid, activity);

    (*ENV)->DeleteLocalRef(ENV, cls);
    (*ENV)->DeleteLocalRef(ENV, cls_name);
}

char* helper_get_locale() {
	static char* retval = NULL;

    if (!retval) {
        jmethodID mid = (*ENV)->GetStaticMethodID(ENV, helper_cls, "locale", "()Ljava/lang/String;");
        jstring jlocale = (*ENV)->CallStaticObjectMethod(ENV, helper_cls, mid);
        const char* clocale = (*ENV)->GetStringUTFChars(ENV, jlocale, NULL);
        retval = malloc(strlen(clocale) + 1);
        strcpy(retval, clocale);

        (*ENV)->ReleaseStringUTFChars(ENV, jlocale, clocale);
        (*ENV)->DeleteLocalRef(ENV, jlocale);
    }

    return retval;
}