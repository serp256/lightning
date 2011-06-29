
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

void android_debug_output(value tag, value msg) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",String_val(msg));
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


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRendererInit(JNIEnv *env, jobject jrenderer, jfloat width, jfloat height) {
	DEBUG("lightRender init");
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRendererChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	DEBUGF("GL Changed: %i:%i",width,height);
	if (stage) {
		__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING","stage alredy initialized");
		return;
	}
	/*glViewport(0, 0, width, height);
  glMatrixMode(GL_PROJECTION);
  const float ratio=width/(float)height;
  glLoadIdentity();
  glOrthof(0, 15, 15/ratio, 0, -1, 1);
  glMatrixMode(GL_MODELVIEW); */
	stage = mlstage_create((float)width,(float)height); 
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_lightRender(JNIEnv *env, jobject thiz) {
	//__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","lightRender");
	mlstage_render(stage);
}


// that's all now :-)

