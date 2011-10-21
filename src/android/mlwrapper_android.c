
#include <jni.h>
#include <stdio.h>
#include <unistd.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include "mlwrapper.h"
#include "mlwrapper_android.h"
#include "GLES/gl.h"

#define caml_acquire_runtime_system()
#define caml_release_runtime_system()


static JavaVM *gJavaVM;
static mlstage *stage = NULL;
static jobject jView;
static jobject jActivity;

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	char *argv[] = {"android",NULL};
	caml_startup(argv);
	gJavaVM = vm;
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","caml initialized");
	return JNI_VERSION_1_6; // Check this
}
//{{{ android debug
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

//}}}

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


static jobjectArray jarray_of_mlList(JNIEnv* env, value mlList) 
//берет окэмльный список дуплов и делает из него двумерный массив явовый
{
	value block, duple;
	int flag = 1;
	int count = 0;
	
	//создал массив из двух строчек
	jclass clsstring = (*env)->FindClass(env,"java/lang/String");
	jobjectArray jduple = (*env)->NewObjectArray(env, 2, clsstring, NULL);
	//создал большой массив с элементами маленькими массивами
	jclass jdupleclass = (*env)->GetObjectClass(env, jduple);
	jobjectArray jresult = (*env)->NewObjectArray(env, 5, jdupleclass, NULL);
	(*env)->DeleteLocalRef(env, jduple);
	
	block = mlList;
	while (flag != 0){
		jduple = (*env)->NewObjectArray(env, 2, clsstring, NULL);
  	duple = Field(block,0);
		//берем строчку окэмловского дупла, конвертим ее в си формат
		//затем создаем из нее ява-строчку и эту ява строчку
		//пихаем во временный массив на две ячейки
		jstring jfield1 = (*env)->NewStringUTF(env, String_val(Field(duple,0)));
		(*env)->SetObjectArrayElement(env, jduple, 0, jfield1);
		//То же самое со вторым полем
		jstring jfield2 = (*env)->NewStringUTF(env, String_val(Field(duple,1)));
		(*env)->SetObjectArrayElement(env, jduple, 1, jfield2);
		//Добавляем мелкий массив в большой массив	
		(*env)->SetObjectArrayElement(env, jresult, count, jduple);
		//Освобождаем память занятую временными данным на проходе
		(*env)->DeleteLocalRef(env, jduple);
		(*env)->DeleteLocalRef(env, jfield1);
		(*env)->DeleteLocalRef(env, jfield2);
		count += 1;
  	if Is_block(Field(block,1))
			block = Field(block,1);
		else flag = 0;
	}
	return jresult;
}


value ml_android_connection(value mlurl,value method,value headers,value data) {
  JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0)
  	{ __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()"); }

	jstring jurl = (*env)->NewStringUTF(env, String_val(mlurl));
	jstring jmethod = (*env)->NewStringUTF(env, String_val(method));
	jobjectArray jheaders = jarray_of_mlList(env, headers);
	jstring jdata = (*env)->NewStringUTF(env, String_val(method));
	if Is_block(data) {
		jdata = (*env)->NewStringUTF(env, String_val(data));
	} 
	//и тут уже вызываем ява-метод и передаем ему параметры
	jclass cls = (*env)->GetObjectClass(env, jView);
	jmethodID mid = (*env)->GetMethodID(env, cls, "spawnHttpLoader", "(Ljava/lang/String;Ljava/lang/String;[[Ljava/lang/String;Ljava/lang/String;)I");
	if (mid == NULL) {
 		__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Can't find spawnHttpLoader  method!!!");
		return; // method not found
	}
	//где-то тут надо получить идентификатор лоадера и вернуть его окэмлу, а так же передать в яву
	//чтобы все дальнейшие действия ассоциировались именно с этим лоадером
	jint jloader_id;
	jloader_id = (*env)->CallIntMethod(env, jView, mid, jurl, jmethod, jheaders, jdata);
	value loader_id;
	loader_id = caml_copy_int32(jloader_id);
	return loader_id;	
}

JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlResponse(JNIEnv *env, jobject jloader, jint loader_id, jint jhttpCode, jstring jcontentType, jint jtotalBytes)
{
	DEBUG("IM INSIDE lightURLresponse!!");
  static value *ml_url_response = NULL;
	caml_acquire_runtime_system();
	if (ml_url_response == NULL) 
		ml_url_response = caml_named_value("url_response");

	value contentType, httpCode, totalBytes;
  Begin_roots3(contentType, httpCode, totalBytes);

	contentType = string_of_jstring(env, jcontentType);
	httpCode = caml_copy_int32(jhttpCode);
	totalBytes = caml_copy_int32(jtotalBytes);

	value args[4];
	args[0] = caml_copy_int32(loader_id);
	args[1] = httpCode; 
	args[3] = totalBytes;
	args[2] = contentType;
	caml_callbackN(*ml_url_response,4,args);
	End_roots();
	caml_release_runtime_system();
}

JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlData(JNIEnv *env, jobject jloader, jint loader_id, jarray data) {
	DEBUG("IM INSIDE lightURLData!!-------------------------------------------->>>");
  static value *ml_url_data = NULL;
	DEBUG("GET MEMORY FOR ML_URL_DATA-method pointer");
	caml_acquire_runtime_system();
	if (ml_url_data == NULL) 
		ml_url_data = caml_named_value("url_data");
	int size = (*env)->GetArrayLength(env, data);
	DEBUG("GET SIZE OF DATA, AND ITs = %lld",size);

	value mldata;
	DEBUG("ALLOC MEMORY FOR MLDATA in C");
  Begin_roots1(mldata);
	DEBUG("BEGIN ROOTS");
	mldata = caml_alloc_string(size); 
	DEBUG("ALLOCATE MEMORY IN CAML GC-zone");
	memcpy(String_val(mldata),(*env)->GetByteArrayElements(env,data,0),size);
	DEBUG("MEMCPY");

	caml_callback2(*ml_url_data, caml_copy_int32(loader_id), mldata);
	DEBUG("call caml callback");
	End_roots();
	DEBUG("ENDROOTS");
	caml_release_runtime_system();
	DEBUG("release runtime system");
}

JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlFailed(JNIEnv *env, jobject jloader, jint jloader_id, jint jerror_code, jstring jerror_message) {
  static value *ml_url_failed = NULL;
	caml_acquire_runtime_system();
	if (ml_url_failed == NULL) 
		ml_url_failed = caml_named_value("url_failed"); 

	value error_code,loader_id;
	Begin_roots2(error_code,loader_id);
	error_code = caml_copy_int32(jerror_code);
	loader_id = caml_copy_int32(jloader_id);

	caml_callback3(*ml_url_failed, jloader_id, error_code, string_of_jstring(env, jerror_message));
	End_roots();
	caml_release_runtime_system();
}


JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlComplete(JNIEnv *env, jobject jloader, jint loader_id) {
	DEBUG("COMPLETE++++++++++++++++++++++++++++++++++++++++++++++++++");
  static value *ml_url_complete = NULL;
	caml_acquire_runtime_system();
	if (ml_url_complete == NULL)
		ml_url_complete = caml_named_value("url_complete");
	caml_callback(*ml_url_complete, caml_copy_int32(loader_id));
	caml_release_runtime_system();
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

JNIEXPORT void Java_hello_world_helloworld_activityInit(JNIEnv *env, jobject jactivity) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","activityInit");
	jActivity = (*env)->NewGlobalRef(env,jactivity);
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
	Begin_roots4(touch,touches,globalX,globalY);
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

