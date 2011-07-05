
#include <jni.h>
#include <stdio.h>
#include <unistd.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include "mlwrapper.h"
#include "mlwrapper_android.h"
#include "GLES/gl.h"

static JavaVM *gJavaVM;
static mlstage *stage = NULL;
static jobject jView;

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	char *argv[] = {"android",NULL};
	caml_startup(argv);
	gJavaVM = vm;
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","caml initialized");
	return JNI_VERSION_1_6; // Check this
}

void android_debug_output(value mtag, value msg) {
	char buf[255];
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else tag = String_val(Field(mtag,0));
	sprintf(buf,"LIGHTNING[%s]",tag);
	__android_log_write(ANDROID_LOG_DEBUG,buf,String_val(msg));
}

void android_debug_output_info(value msg) {
	__android_log_write(ANDROID_LOG_INFO,"LIGHTNING",String_val(msg));
}

void android_debug_output_warn(value msg) {
	__android_log_write(ANDROID_LOG_WARN,"LIGHTNING",String_val(msg));
}

void android_debug_output_error(value msg) {
	__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",String_val(msg));
}

void android_debug_output_fatal(value msg) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",String_val(msg));
}


static value string_of_jstring(JNIEnv* env, jstring jstr)
{
	// convert jstring to byte array
	jclass clsstring = (*env)->FindClass(env,"java/lang/String");
	jstring strencode = (*env)->NewStringUTF(env,"utf-8");
	jmethodID mid = (*env)->GetMethodID(env,clsstring, "getBytes", "(Ljava/lang/String;)[B");
	jbyteArray barr= (jbyteArray)(*env)->CallObjectMethod(env,jstr, mid, strencode);
	jsize alen =  (*env)->GetArrayLength(env,barr);
	jbyte* ba = (*env)->GetByteArrayElements(env,barr, JNI_FALSE);

	value result = caml_alloc_string(alen);
	// copy byte array into char[]
	if (alen > 0)
	{
		memcpy(String_val(result), ba, alen);
	}
	(*env)->ReleaseByteArrayElements(env,barr, ba, 0);

	return result;
}

// maybe rewrite it for libzip
int getResourceFd(value mlpath, resource *res) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0)
	{
		__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
	}
	jclass cls = (*env)->GetObjectClass(env,jView);
	jmethodID mthd = (*env)->GetMethodID(env,cls,"getResource","(Ljava/lang/String;)Lru/redspell/lightning/ResourceParams;");
	if (!mthd) __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Cant find getResource method");
	jstring jpath = (*env)->NewStringUTF(env,String_val(mlpath));
	jobject resourceParams = (*env)->CallObjectMethod(env,jView,mthd,jpath);
	if (!resourceParams) return 0;
	cls = (*env)->GetObjectClass(env,resourceParams);

	jfieldID fid = (*env)->GetFieldID(env,cls,"fd","Ljava/io/FileDescriptor;");
	jobject fileDescriptor = (*env)->GetObjectField(env,resourceParams,fid);
	jclass fdcls = (*env)->GetObjectClass(env,fileDescriptor);
	fid = (*env)->GetFieldID(env,fdcls,"descriptor","I");
	jint fd = (*env)->GetIntField(env,fileDescriptor,fid);

	fid = (*env)->GetFieldID(env,cls,"startOffset","J");
	jlong startOffset = (*env)->GetLongField(env,resourceParams,fid);

	fid = (*env)->GetFieldID(env,cls,"length","J");
	jlong length = (*env)->GetLongField(env,resourceParams,fid);
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","startOffset: %lld, length: %lld",startOffset,length);
	int myfd = dup(fd); 
	lseek(myfd,startOffset,SEEK_SET);
	res->fd = myfd;
	res->length = length;
	return 1;
}

// получим параметры нах
value caml_getResource(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal2(res,mlfd);
	resource r;
	if (getResourceFd(mlpath,&r)) {
		mlfd = caml_alloc_tuple(2);
		Store_field(mlfd,0,Val_int(r.fd));
		Store_field(mlfd,1,caml_copy_int64(r.length));
		res = caml_alloc_tuple(1);
		Store_field(res,0,mlfd);
		//FILE* myFile = fdopen(myfd, "rb"); 
		/*
		if (myFile) 
		{ 
			fseek(myFile, startOffset, SEEK_SET); 
			char *test = malloc(length+1);
			size_t readed = fread(test,length,1,myFile);
			test[length] = '\0';
			__android_log_print(ANDROID_LOG_DEBUG,"TEST","readed: %d bytes [%s]",readed,test);
		} */
	} else res = Val_int(0); 
	CAMLreturn(res);
}


/*
JNIEXPORT void Java_ru_redspell_lightning_LightView_lightSetResourcesPath(JNIEnv *env, jobject thiz, jstring apkFilePath) {
	value mls = string_of_jstring(env,apkFilePath);
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","lightSetResourcePath: [%s]",String_val(mls));
	caml_callback(*caml_named_value("setResourcesBase"),mls);
}
*/

JNIEXPORT void Java_ru_redspell_lightning_LightView_lightInit(JNIEnv *env, jobject jview) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","lightInit");
	jView = (*env)->NewGlobalRef(env,jview);
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRendererInit(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	DEBUG("lightRender init");
	if (stage) {
		__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING","stage alredy initialized");
		caml_callback(*caml_named_value("realodTextures"),Val_int(0));
		// we need reload textures
		return;
	}
	DEBUGF("create stage: [%d:%d]",width,height);
	stage = mlstage_create((double)width,(double)height); 
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRendererChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	DEBUGF("GL Changed: %i:%i",width,height);
}



static value run_method = 1;//None
void mlstage_run(double timePassed) {
	if (run_method == 1) // None
		run_method = caml_hash_variant("run");
	caml_callback2(caml_get_public_method(stage->stage,run_method),stage->stage,caml_copy_double(timePassed));
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRender(JNIEnv *env, jobject thiz, jlong interval) {
	double timePassed = (double)interval / 1000000000L;
	mlstage_run(timePassed);
}


// Touches 

void fireTouch(jint id, jfloat x, jfloat y, int phase) {
	value touch,touches = 1;
	Begin_roots1(touch);
	touch = caml_alloc_tuple(8);
	Store_field(touch,0,caml_copy_int32(id));
	Store_field(touch,1,caml_copy_double(0.));
	Store_field(touch,2,caml_copy_double(x));
	Store_field(touch,3,caml_copy_double(y));
	Store_field(touch,4,1);// None
	Store_field(touch,5,1);// None
	Store_field(touch,6,Val_int(1));// tap_count
	Store_field(touch,7,Val_int(phase)); 
	touches = caml_alloc_small(2,0);
	Field(touches,0) = touch;
	Field(touches,1) = 1; // None
	End_roots();
  mlstage_processTouches(stage,touches);
}

void fireTouches(JNIEnv *env, jintArray ids, jfloatArray xs, jfloatArray ys, int phase) {
	int size = (*env)->GetArrayLength(env,ids);
	jint id[size];
	jfloat x[size];
	jfloat y[size];
	(*env)->GetIntArrayRegion(env,ids,0,size,id);
	(*env)->GetFloatArrayRegion(env,xs,0,size,x);
	(*env)->GetFloatArrayRegion(env,ys,0,size,y);
	value touch,globalX,globalY,lst_el,touches;
	Begin_roots2(touch,touches,globalX,globalY);
	int i = 0;
	touches = 1;
	for (i = 0; i < size; i++) {
		globalX = caml_copy_double(x[i]);
		globalY = caml_copy_double(y[i]);
		touch = caml_alloc_tuple(8);
		Store_field(touch,0,caml_copy_int32(id[i]));
		Store_field(touch,1,caml_copy_double(0.));
		Store_field(touch,2,globalX);
		Store_field(touch,3,globalY);
		Store_field(touch,4,globalX);
		Store_field(touch,5,globalY);
		Store_field(touch,6,Val_int(1));// tap_count
		Store_field(touch,7,Val_int(phase)); 
		lst_el = caml_alloc_small(2,0);
    Field(lst_el,0) = touch;
    Field(lst_el,1) = touches;
    touches = lst_el;
	}
  mlstage_processTouches(stage,touches);
	End_roots();
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleActionDown(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y) {
	fireTouch(id,x,y,0);//TouchePhaseBegan = 0
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleActionUp(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y) {
	fireTouch(id,x,y,3);//TouchePhaseEnded = 3
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleActionCancel(JNIEnv *env, jobject thiz, jarray ids, jarray xs, jarray ys) {
	fireTouches(env,ids,xs,ys,4);//TouchePhaseCanceled = 4
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleActionMove(JNIEnv *env, jobject thiz, jarray ids, jarray xs, jarray ys) {
	fireTouches(env,ids,xs,ys,1);//TouchePhaseMoved = 1
}

/*
JNIEXPORT void Java_ru_redspell_lightning_lightRenderer_handlekeydown(int keycode) {
}
*/

// that's all now :-)

