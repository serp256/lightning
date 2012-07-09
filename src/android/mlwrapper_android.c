
#include <jni.h>
#include <stdio.h>
#include <unistd.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include "mlwrapper.h"
#include "mlwrapper_android.h"
#include "GLES/gl.h"
#include "net_curl.h"
#include "render_stub.h"
#include <fcntl.h>


#define caml_acquire_runtime_system()
#define caml_release_runtime_system()

static JavaVM *gJavaVM;
static int ocaml_initialized = 0;
static mlstage *stage = NULL;
static jobject jView;
static jclass jViewCls;
static jobject jStorage;
static jobject jStorageEditor;

static jclass gSndPoolCls = NULL;
static jobject gSndPool = NULL;


typedef enum 
  { 
    St_int_val, 
    St_bool_val, 
    St_string_val, 
  } st_val_type;

static void mlUncaughtException(const char* exn, int bc, char** bv) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",exn);
	int i;
	for (i = 0; i < bc; i++) {
		if (bv[i]) __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",bv[i]);
	};
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	uncaught_exception_callback = &mlUncaughtException;
	gJavaVM = vm;
	return JNI_VERSION_1_6; // Check this
}

void android_debug_output(value mtag, value address, value msg) {
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else tag = String_val(Field(mtag,0));
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s (%s)] %s",tag,String_val(address),String_val(msg)); // this should be APPNAME
}

void android_debug_output_info(value address,value msg) {
	__android_log_write(ANDROID_LOG_INFO,"LIGHTNING",String_val(msg));
}

void android_debug_output_warn(value address,value msg) {
	__android_log_write(ANDROID_LOG_WARN,"LIGHTNING",String_val(msg));
}

void android_debug_output_error(value address, value msg) {
	__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",String_val(msg));
}

void android_debug_output_fatal(value address, value msg) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",String_val(msg));
}


/*
static value string_of_jstring(JNIEnv* env, jstring jstr)
{
	// convert jstring to byte array
	jclass clsstring = (*env)->FindClass(env,"java/lang/String");
	const char * utf = "utf-8";
	jstring strencode = (*env)->NewStringUTF(env,utf);
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
	
	(*env)->DeleteLocalRef(env, strencode);
	(*env)->DeleteLocalRef(env, clsstring);
	(*env)->DeleteLocalRef(env, mid);
		
	return result;
}
*/

static char *gAssetsDir = NULL;

JNIEXPORT void Java_ru_redspell_lightning_LightView_assetsExtracted(JNIEnv *env, jobject this, jstring assetsDir) {
	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, 0);

	if (assetsDir != NULL) {
		const char *path = (*env)->GetStringUTFChars(env, assetsDir, JNI_FALSE);
		gAssetsDir = (char*) malloc(strlen(path));
		strcpy(gAssetsDir, path);		
	}
}

// NEED rewrite it for libzip
int getResourceFd(const char *path, resource *res) { //{{{
	DEBUGF("getResourceFD: %s",path);

	if (gAssetsDir != NULL) {
		char *assetPath = (char*) malloc(strlen(gAssetsDir) + strlen(path) + 1);
		strcpy(assetPath, gAssetsDir);
		strcat(assetPath, "/");
		strcat(assetPath, path);

		int fd = open(assetPath, O_RDONLY);
		free(assetPath);

		if (fd < 0) {
			return 0;
		}

		res->fd = fd;
		res->length = lseek(fd, 0, SEEK_END);
		lseek(fd, 0, SEEK_SET);
	} else {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
		if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0)
		{
			__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
		}

		jclass cls = (*env)->GetObjectClass(env,jView);
		jmethodID mthd = (*env)->GetMethodID(env,cls,"getResource","(Ljava/lang/String;)Lru/redspell/lightning/ResourceParams;");
		(*env)->DeleteLocalRef(env, cls); //
		
		if (!mthd) __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Cant find getResource method");
		
		jstring jpath = (*env)->NewStringUTF(env,path);
		jobject resourceParams = (*env)->CallObjectMethod(env,jView,mthd,jpath);
		(*env)->DeleteLocalRef(env,jpath);
		
		if (!resourceParams) {
		  return 0;
		}
		
		cls = (*env)->GetObjectClass(env,resourceParams);
		
		jfieldID fid = (*env)->GetFieldID(env,cls,"fd","Ljava/io/FileDescriptor;");
		
		jobject fileDescriptor = (*env)->GetObjectField(env,resourceParams,fid);
		jclass fdcls = (*env)->GetObjectClass(env,fileDescriptor);
		
		fid = (*env)->GetFieldID(env,fdcls,"descriptor","I");

	//3	(*env)->DeleteLocalRef(env, fdcls);
		jint fd = (*env)->GetIntField(env,fileDescriptor,fid);
		fid = (*env)->GetFieldID(env,cls,"startOffset","J");
		jlong startOffset = (*env)->GetLongField(env,resourceParams,fid);
		fid = (*env)->GetFieldID(env,cls,"length","J");
		jlong length = (*env)->GetLongField(env,resourceParams,fid);

		//__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","startOffset: %lld, length: %lld (%s)",startOffset,length, String_val(mlpath));
		
		int myfd = dup(fd); 
		lseek(myfd,startOffset,SEEK_SET);
		res->fd = myfd;
		res->length = length;
		
		(*env)->DeleteLocalRef(env, fileDescriptor);
		(*env)->DeleteLocalRef(env, resourceParams);
		(*env)->DeleteLocalRef(env, cls);		
	}

	return 1;
}//}}}

// получим параметры нах
value caml_getResource(value mlpath,value suffix) {
	CAMLparam1(mlpath);
	CAMLlocal2(res,mlfd);
	resource r;
	if (getResourceFd(String_val(mlpath),&r)) {
		mlfd = caml_alloc_tuple(2);
		Store_field(mlfd,0,Val_int(r.fd));
		Store_field(mlfd,1,caml_copy_int64(r.length));
		res = caml_alloc_tuple(1);
		Store_field(res,0,mlfd);
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

JNIEXPORT void Java_ru_redspell_lightning_LightView_lightInit(JNIEnv *env, jobject jview, jobject storage) {
	DEBUG("lightInit");

	jView = (*env)->NewGlobalRef(env,jview);

	jclass viewCls = (*env)->GetObjectClass(env, jView);
	jViewCls = (*env)->NewGlobalRef(env, viewCls);

	
	/*
	jclass viewCls = (*env)->GetObjectClass(env,jView);
	jmethodID getContextMthd = (*env)->GetMethodID(env, viewCls,"getContext","()Landroid/content/Context;");
	jobject contextObj = (*env)->CallObjectMethod(env,jView,getContextMthd);
	
	jclass contextCls = (*env)->GetObjectClass(env, contextObj);
	jmethodID getSharedPreferencesMthd = (*env)->GetMethodID(env, contextCls, "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;");  
	jstring stname = (*env)->NewStringUTF(env, "lightning");
	
	jobject storage = (*env)->CallObjectMethod(env,contextObj, getSharedPreferencesMthd,stname,0);
	*/

	jStorage = (*env)->NewGlobalRef(env, storage);

	/* editor */
	jclass storageCls = (*env)->GetObjectClass(env, storage);
	jmethodID jmthd_edit = (*env)->GetMethodID(env, storageCls, "edit", "()Landroid/content/SharedPreferences$Editor;");
	jobject storageEditor = (*env)->CallObjectMethod(env, storage, jmthd_edit);
	jStorageEditor = (*env)->NewGlobalRef(env, storageEditor);
  
      
	//(*env)->DeleteLocalRef(env, storage);
	//(*env)->DeleteLocalRef(env, stname);
	//(*env)->DeleteLocalRef(env, contextCls);
	//(*env)->DeleteLocalRef(env, contextObj);
	//(*env)->DeleteLocalRef(env, viewCls);
	DEBUG("delete local references 0");
	(*env)->DeleteLocalRef(env, storageCls);
	DEBUG("delete local references 1");
	(*env)->DeleteLocalRef(env, storageEditor);
	DEBUG("delete local references 2");
	(*env)->DeleteLocalRef(env, viewCls);
	DEBUG("delete local references 3");
	if (!ocaml_initialized) {
		DEBUG("init ocaml");
		char *argv[] = {"android",NULL};
		caml_startup(argv);
		ocaml_initialized = 1;
		DEBUG("caml initialized");
	}
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceCreated(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	DEBUG("lightRender init");
	if (stage) return;
	DEBUGF("create stage: [%d:%d]",width,height);
	stage = mlstage_create((double)width,(double)height); 
	DEBUGF("stage created");
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	DEBUGF("GL Changed: %i:%i",width,height);
}



static value run_method = 1;//None
void mlstage_run(double timePassed) {
	if (run_method == 1) // None
		run_method = caml_hash_variant("run");
	if (net_running > 0) net_perform();
	caml_callback2(caml_get_public_method(stage->stage,run_method),stage->stage,caml_copy_double(timePassed));
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeDrawFrame(JNIEnv *env, jobject thiz, jlong interval) {
	double timePassed = (double)interval / 1000000000L;
	mlstage_run(timePassed);
}


// Touches 

void fireTouch(jint id, jfloat x, jfloat y, int phase) {
	value touch,touches = 1;
	Begin_roots1(touch);
	touch = caml_alloc_tuple(8);
	Store_field(touch,0,caml_copy_int32(id + 1));
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
		Store_field(touch,0,caml_copy_int32(id[i] + 1));
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

/*
static jobjectArray jarray_of_mlList(JNIEnv* env, value mlList) 
//берет окэмльный список дуплов и делает из него двумерный массив явовый
{
	value block, tuple;
	int count = 0;

	//создал массив из двух строчек
	jclass clsstring = (*env)->FindClass(env,"java/lang/String");
	jobjectArray jtuple = (*env)->NewObjectArray(env, 2, clsstring, NULL);
		
	//создал большой массив с элементами маленькими массивами
	jclass jtupleclass = (*env)->GetObjectClass(env, jtuple);
	jobjectArray jresult = (*env)->NewObjectArray(env, 5, jtupleclass, NULL);
	(*env)->DeleteLocalRef(env, jtuple);
	
	block = mlList;
	
	while (Is_block(block)) {
		jtuple = (*env)->NewObjectArray(env, 2, clsstring, NULL);
    	tuple = Field(block,0);
    	
		//берем строчку окэмловского дупла, конвертим ее в си формат
		//затем создаем из нее ява-строчку и эту ява строчку
		//пихаем во временный массив на две ячейки
		
		jstring jfield1 = (*env)->NewStringUTF(env, String_val(Field(tuple,0)));
		
		(*env)->SetObjectArrayElement(env, jtuple, 0, jfield1);
		
		//То же самое со вторым полем
		
		jstring jfield2 = (*env)->NewStringUTF(env, String_val(Field(tuple,1)));
		
		(*env)->SetObjectArrayElement(env, jtuple, 1, jfield2);
		
		//Добавляем мелкий массив в большой массив	
		
		(*env)->SetObjectArrayElement(env, jresult, count, jtuple);
		
		//Освобождаем память занятую временными данным на проходе
		
		(*env)->DeleteLocalRef(env, jtuple);
		(*env)->DeleteLocalRef(env, jfield1);
		(*env)->DeleteLocalRef(env, jfield2);
		count += 1;
  
  	    block = Field(block,1);
	}
	return jresult;
}

value ml_android_connection(value mlurl,value method,value headers,value data) {
  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) { 
    __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()"); 
  }

  
  jobjectArray jheaders = jarray_of_mlList(env, headers);
  
  jbyteArray jdata;
  
  if (Is_block(data)) {
    unsigned int len = caml_string_length(Field(data,0));
    
    DEBUGF("Data length is %ud bytes", len);  
    
    jdata = (*env)->NewByteArray(env, len);
    (*env)->SetByteArrayRegion(env, jdata, 0, len, (const jbyte *)String_val(Field(data,0)));
  } else {
    jdata = (*env)->NewByteArray(env, 0);
  }
  
  //и тут уже вызываем ява-метод и передаем ему параметры
  jclass cls = (*env)->GetObjectClass(env, jView);
  jmethodID mid = (*env)->GetMethodID(env, cls, "spawnHttpLoader", "(Ljava/lang/String;Ljava/lang/String;[[Ljava/lang/String;[B)I");
  if (mid == NULL) {
  	return Val_int(0); // method not found
  }

  const char * url = String_val(mlurl);
  const char * meth = String_val(method);

  jstring jurl = (*env)->NewStringUTF(env, url);
  jstring jmethod = (*env)->NewStringUTF(env, meth);
	
  //где-то тут надо получить идентификатор лоадера и вернуть его окэмлу, а так же передать в яву
  //чтобы все дальнейшие действия ассоциировались именно с этим лоадером
  jint jloader_id = (*env)->CallIntMethod(env, jView, mid, jurl, jmethod, jheaders, jdata);
  value loader_id = caml_copy_int32(jloader_id);
  
  (*env)->DeleteLocalRef(env, cls);
  (*env)->DeleteLocalRef(env, jdata);
  (*env)->DeleteLocalRef(env, jurl);
  (*env)->DeleteLocalRef(env, jmethod);
  
  return loader_id;
}


JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlResponse(JNIEnv *env, jobject jloader, jint loader_id, jint jhttpCode, jstring jcontentType, jint jtotalBytes) {
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
	caml_acquire_runtime_system();

	if (ml_url_data == NULL) ml_url_data = caml_named_value("url_data");

	int size = (*env)->GetArrayLength(env, data);
	
	value mldata;
  
	Begin_roots1(mldata);
	mldata = caml_alloc_string(size); 
	jbyte * javadata = (*env)->GetByteArrayElements(env,data,0);
	memcpy(String_val(mldata),javadata,size);
	(*env)->ReleaseByteArrayElements(env,data,javadata,0);

	caml_callback2(*ml_url_data, caml_copy_int32(loader_id), mldata);
	End_roots();
	caml_release_runtime_system();
}


JNIEXPORT void Java_ru_redspell_lightning_LightHttpLoader_lightUrlFailed(JNIEnv *env, jobject jloader, jint jloader_id, jint jerror_code, jstring jerror_message) {
  DEBUG("FAILURE ------------");
  static value *ml_url_failed = NULL;
  caml_acquire_runtime_system();

  if (ml_url_failed == NULL) 
    ml_url_failed = caml_named_value("url_failed"); 

  value error_code,loader_id;
  Begin_roots2(error_code, loader_id);
  error_code = caml_copy_int32(jerror_code);
  loader_id = caml_copy_int32(jloader_id);
  End_roots();
  caml_callback3(*ml_url_failed, loader_id, error_code, string_of_jstring(env, jerror_message));
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
*/



//////////// key-value storage based on NSUserDefaults

/*
value ml_kv_storage_create() {
  CAMLparam0();
  CAMLreturn((value)jStorage);
}
*/

static int kv_storage_synced = 1;


// commit
void ml_kv_storage_commit(value unit) {

	DEBUG("kv_storage_commit");
  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  /*if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }*/

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
	static jmethodID jmthd_commit = NULL;
	if (jmthd_commit == NULL) jmthd_commit = (*env)->GetMethodID(env, editorCls, "commit", "()Z");
  (*env)->CallBooleanMethod(env, jStorageEditor, jmthd_commit);
  (*env)->DeleteLocalRef(env, editorCls);
	kv_storage_synced = 1;
}


static void kv_storage_apply(JNIEnv *env) {
	DEBUG("kv_storage_apply");
  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
	static jmethodID jmthd_apply = NULL;
	if (jmthd_apply == NULL) jmthd_apply = (*env)->GetMethodID(env, editorCls, "apply", "()V");
  (*env)->CallVoidMethod(env, jStorageEditor, jmthd_apply);
  (*env)->DeleteLocalRef(env, editorCls);
	kv_storage_synced = 1;
}


// 
jboolean kv_storage_contains_key(JNIEnv *env, jstring key) {
	DEBUG("kv_storage_contains_key");
  jclass storageCls = (*env)->GetObjectClass(env, jStorage);
  static jmethodID jmthd_contains = NULL;
	if (jmthd_contains == NULL) jmthd_contains = (*env)->GetMethodID(env, storageCls, "contains", "(Ljava/lang/String;)Z");
  jboolean contains = (*env)->CallBooleanMethod(env, jStorage, jmthd_contains, key);
  (*env)->DeleteLocalRef(env, storageCls);
  return contains;
} 


value kv_storage_get_val(value key_ml, st_val_type vtype) {
  CAMLparam1(key_ml);
  CAMLlocal1(tuple);
	DEBUGF("kv_storage_get_val: %s",String_val(key_ml));
  
  JNIEnv *env;                                                                                                                                                                                
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);                                                                                                                                   
	/*
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {                                                                                                                                 
    __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");                                                                           
  };*/  

	if (!kv_storage_synced) kv_storage_apply(env);
	DEBUG("KV_STORAGE_SYNCED");
  
  jclass  storageCls = (*env)->GetObjectClass(env, jStorage);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));

  if (!kv_storage_contains_key(env, key)) {
    (*env)->DeleteLocalRef(env, storageCls);
    (*env)->DeleteLocalRef(env, key);
    CAMLreturn(Val_int(0));
  }


  tuple = caml_alloc_tuple(1);
  
  if (vtype == St_string_val) {
		static jmethodID jmthd_getString = NULL;
		if (jmthd_getString == NULL) jmthd_getString = (*env)->GetMethodID(env, storageCls, "getString", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;");
    jstring jval = (*env)->CallObjectMethod(env, jStorage, jmthd_getString, key, NULL);
		jsize slen = (*env)->GetStringUTFLength(env,jval);
		DEBUGF("GET STRING: %s len: %d",String_val(key_ml),slen);
    const char *val = (*env)->GetStringUTFChars(env, jval, NULL);
		value mval = caml_alloc_string(slen);
		memcpy(String_val(mval),val,slen);
    Store_field(tuple,0,mval);
    (*env)->ReleaseStringUTFChars(env, jval, val);
    (*env)->DeleteLocalRef(env, jval);
  } else if (vtype == St_int_val) {
		static jmethodID jmthd_getInt = NULL;
		if (jmthd_getInt == NULL) jmthd_getInt = (*env)->GetMethodID(env, storageCls, "getInt", "(Ljava/lang/String;I)I");
    jint jval = (*env)->CallIntMethod(env, jStorage, jmthd_getInt, key, 0);
    Store_field(tuple,0,Val_int(jval));
  } else {
		static jmethodID jmthd_getBool = NULL;
		if (jmthd_getBool == NULL) jmthd_getBool = (*env)->GetMethodID(env, storageCls, "getBoolean", "(Ljava/lang/String;Z)Z");
    jboolean jval = (*env)->CallBooleanMethod(env, jStorage, jmthd_getBool, key, 0);
    Store_field(tuple,0,Val_bool(jval));
  }
  
  
  (*env)->DeleteLocalRef(env, storageCls);
  (*env)->DeleteLocalRef(env, key);

  //(*gJavaVM)->DetachCurrentThread(gJavaVM);

  CAMLreturn(tuple);
}



// get string
value ml_kv_storage_get_string(value key_ml) {
  return kv_storage_get_val(key_ml, St_string_val);
}  

// get boolean
value ml_kv_storage_get_bool(value key_ml) {
  return kv_storage_get_val(key_ml, St_bool_val);
}

// get int 
value ml_kv_storage_get_int(value key_ml) {
  return kv_storage_get_val(key_ml, St_int_val);
}

// get float 
value ml_kv_storage_get_float(value key_ml) {
	return caml_copy_double(1.);
  //return kv_storage_get_val(key_ml, St_int_val);
}

void kv_storage_put_val(value key_ml, value val_ml, st_val_type vtype) {
  CAMLparam2(key_ml, val_ml);

	DEBUGF("kv_storage_put_val %s",String_val(key_ml));
  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	/*
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }*/

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));
	DEBUG (String_val(key_ml));
  
  if (vtype == St_string_val) {
		static jmethodID jmthd_putString = NULL;
		if (jmthd_putString == NULL) jmthd_putString = (*env)->GetMethodID(env, editorCls, "putString", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;");
    jstring val = (*env)->NewString(env, String_val(val_ml),caml_string_length(val_ml));
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_putString, key, val);
    (*env)->DeleteLocalRef(env, val);
  } else if (vtype == St_bool_val) {
		static jmethodID jmthd_putBool = NULL;
		if (jmthd_putBool == NULL) jmthd_putBool = (*env)->GetMethodID(env, editorCls, "putBoolean", "(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;");
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_putBool, key, Bool_val(val_ml));
  } else {
		static jmethodID jmthd_putInt = NULL;
		if (jmthd_putInt == NULL) jmthd_putInt = (*env)->GetMethodID(env, editorCls, "putInt", "(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;");
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_putInt, key, Int_val(val_ml));
  }
      
	kv_storage_synced = 0;
  (*env)->DeleteLocalRef(env, key);
  (*env)->DeleteLocalRef(env, editorCls);

  //(*gJavaVM)->DetachCurrentThread(gJavaVM);

  CAMLreturn0;
}


// put string
void ml_kv_storage_put_string(value key_ml, value val_ml) {
  return kv_storage_put_val(key_ml, val_ml, St_string_val);
}


void ml_kv_storage_put_bool(value key_ml, value val_ml) {
  return kv_storage_put_val(key_ml, val_ml, St_bool_val);
}


void ml_kv_storage_put_int(value key_ml, value val_ml) {
  return kv_storage_put_val(key_ml, val_ml, St_int_val);
}

void ml_kv_storage_put_float(value key_ml, value val_ml) {
  //return kv_storage_put_val(key_ml, val_ml, St_int_val);
}


void ml_kv_storage_remove(value key_ml) {
  CAMLparam1(key_ml);

	DEBUGF("kv_storage_remove: %s",String_val(key_ml));

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	/*
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }*/

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));

  jmethodID jmthd_remove = NULL;
	if (jmthd_remove == NULL) jmthd_remove = (*env)->GetMethodID(env, editorCls, "remove", "(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;");
  jobject e =  (*env)->CallObjectMethod(env, jStorageEditor, jmthd_remove, key);

	kv_storage_synced = 0;
  (*env)->DeleteLocalRef(env, key);
  (*env)->DeleteLocalRef(env, e);

  //(*gJavaVM)->DetachCurrentThread(gJavaVM);

  CAMLreturn0;
}


value ml_kv_storage_exists(value key_ml) {
  CAMLparam1(key_ml);

	DEBUGF("kv_storage_exists: %s",String_val(key_ml));
  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	/*
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }
	*/
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml)); 
  jboolean contains = kv_storage_contains_key(env, key);
  (*env)->DeleteLocalRef(env,key);
  CAMLreturn(Val_bool(contains));
}


value ml_malinfo(value p) {
	return caml_alloc_tuple(3);
}

void ml_alsoundInit() {
	if (gSndPool != NULL) {
		caml_failwith("alsound already initialized");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jclass amCls = (*env)->FindClass(env, "android/media/AudioManager");
	jfieldID strmTypeFid = (*env)->GetStaticFieldID(env, amCls, "STREAM_MUSIC", "I");
	jint strmType = (*env)->GetStaticIntField(env, amCls, strmTypeFid);

	jclass sndPoolCls = (*env)->FindClass(env, "android/media/SoundPool");
	jmethodID constrId = (*env)->GetMethodID(env, sndPoolCls, "<init>", "(III)V");
	jobject sndPool = (*env)->NewObject(env, sndPoolCls, constrId, 100, strmType, 0);

	gSndPoolCls = (*env)->NewGlobalRef(env, sndPoolCls);
	gSndPool = (*env)->NewGlobalRef(env, sndPool);

	(*env)->DeleteLocalRef(env, amCls);
	(*env)->DeleteLocalRef(env, sndPoolCls);
	(*env)->DeleteLocalRef(env, sndPool);
}

static jmethodID gGetSndIdMthdId = NULL;

value ml_alsoundLoad(value path) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then again Sound.load");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gGetSndIdMthdId == NULL) {
		gGetSndIdMthdId = (*env)->GetMethodID(env, jViewCls, "getSoundId", "(Ljava/lang/String;Landroid/media/SoundPool;)I");
	}

	jstring jpath = (*env)->NewStringUTF(env, String_val(path));
	jint sndId = (*env)->CallIntMethod(env, jView, gGetSndIdMthdId, jpath, gSndPool);
	(*env)->DeleteLocalRef(env, jpath);

	return Val_int(sndId);
}

static jmethodID gPlayMthdId = NULL;

value ml_alsoundPlay(value soundId, value vol, value loop) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#play");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gPlayMthdId == NULL) {
		gPlayMthdId = (*env)->GetMethodID(env, gSndPoolCls, "play", "(IFFIIF)I");
	}

	jdouble jvol = Double_val(vol);

	jint streamId = (*env)->CallIntMethod(env, gSndPool, gPlayMthdId, Int_val(soundId), jvol, jvol, 0, Bool_val(loop) ? -1 : 0, 1.0);

	return Val_int(streamId);
}

static jmethodID gPauseMthdId = NULL;

void ml_alsoundPause(value streamId) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#pause");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gPauseMthdId == NULL) {
		gPauseMthdId = (*env)->GetMethodID(env, gSndPoolCls, "pause", "(I)V");
	}
 
	(*env)->CallVoidMethod(env, gSndPool, gPauseMthdId, Int_val(streamId));
}

static jmethodID gStopMthdId = NULL;

void ml_alsoundStop(value streamId) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#stop");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gStopMthdId == NULL) {
		gStopMthdId = (*env)->GetMethodID(env, gSndPoolCls, "stop", "(I)V");
	}

	(*env)->CallVoidMethod(env, gSndPool, gStopMthdId, Int_val(streamId));

	DEBUGF("ml_alsoundStop call %d", Int_val(streamId));
}

static jmethodID gSetVolMthdId = NULL;

void ml_alsoundSetVolume(value streamId, value vol) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#setVolume");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gSetVolMthdId == NULL) {
		gSetVolMthdId = (*env)->GetMethodID(env, gSndPoolCls, "setVolume", "(IFF)V");
	}

	jdouble jvol = Double_val(vol);
	(*env)->CallVoidMethod(env, gSndPool, gSetVolMthdId, Int_val(streamId), jvol, jvol);
}

static jmethodID gSetLoopMthdId = NULL;

void ml_alsoundSetLoop(value streamId, value loop) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#setLoop");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gSetLoopMthdId == NULL) {
		gSetLoopMthdId = (*env)->GetMethodID(env, gSndPoolCls, "setLoop", "(II)V");
	}

	(*env)->CallVoidMethod(env, gSndPool, gSetLoopMthdId, Int_val(streamId), Bool_val(loop) ? -1 : 0);	
}

static jmethodID gAutoPause = NULL;
static jmethodID gAutoResume = NULL;

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnPause(JNIEnv *env, jobject this) {
	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		if (gAutoPause == NULL) {
			gAutoPause = (*env)->GetMethodID(env, gSndPoolCls, "autoPause", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoPause);
	}
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnResume(JNIEnv *env, jobject this) {
	DEBUGF("Java_ru_redspell_lightning_LightRenderer_handleOnResume call");

	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
		
		if (gAutoResume == NULL) {
			gAutoResume = (*env)->GetMethodID(env, gSndPoolCls, "autoResume", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoResume);

		DEBUG("pizda");
	}

	DEBUG("xyu");
}

void ml_paymentsTest() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jmethodID mthdId = (*env)->GetMethodID(env, jViewCls, "initBillingServ", "()V");
	(*env)->CallIntMethod(env, jView, mthdId);
}

static value successCb = 0;
static value errorCb = 0;

void ml_payment_init(value pubkey, value scb, value ecb) {

	if (successCb == 0) {
		successCb = scb;
		caml_register_generational_global_root(&successCb);
		errorCb = ecb;
		caml_register_generational_global_root(&errorCb);
	} else {
		caml_modify_generational_global_root(&successCb,scb);
		caml_modify_generational_global_root(&errorCb,ecb);
	}

	if (!Is_long(pubkey)) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		jclass securityCls = (*env)->FindClass(env, "ru/redspell/lightning/payments/Security");
		jmethodID setPubkey = (*env)->GetStaticMethodID(env, securityCls, "setPubkey", "(Ljava/lang/String;)V");
		jstring jpubkey = (*env)->NewStringUTF(env, String_val(Field(pubkey, 0)));

		(*env)->CallStaticVoidMethod(env, securityCls, setPubkey, jpubkey);

		(*env)->DeleteLocalRef(env, securityCls);
		(*env)->DeleteLocalRef(env, jpubkey);
	}
}

void payments_destroy() {
	if (successCb) {
		caml_remove_generational_global_root(&successCb);
		successCb = 0;
		caml_remove_generational_global_root(&errorCb);
		errorCb = 0;
	};
}

static jmethodID gRequestPurchase;

void ml_payment_purchase(value prodId) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gRequestPurchase == NULL) {
		gRequestPurchase = (*env)->GetMethodID(env, jViewCls, "requestPurchase", "(Ljava/lang/String;)V");
	}

	jstring jprodId = (*env)->NewStringUTF(env, String_val(prodId));
	(*env)->CallVoidMethod(env, jView, gRequestPurchase, jprodId);
	(*env)->DeleteLocalRef(env, jprodId);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb(JNIEnv *env, jobject this, jstring prodId, jstring notifId, jstring signedData, jstring signature) {
	CAMLparam0();
	CAMLlocal2(tr, vprodId);

	if (!successCb) return; //caml_failwith("payment callbacks are not initialized");

	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
	const char *cnotifId = (*env)->GetStringUTFChars(env, notifId, JNI_FALSE);
	const char *csignature = (*env)->GetStringUTFChars(env, signature, JNI_FALSE);
	const char *csignedData = (*env)->GetStringUTFChars(env, signedData, JNI_FALSE);	

	tr = caml_alloc_tuple(3);
	vprodId = caml_copy_string(cprodId);

	Store_field(tr, 0, caml_copy_string(cnotifId));
	Store_field(tr, 1, caml_copy_string(csignedData));
	Store_field(tr, 2, caml_copy_string(csignature));

	caml_callback3(successCb, vprodId, tr, Val_true);

	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentErrorCb(JNIEnv *env, jobject this, jstring prodId, jstring mes) {
	CAMLparam0();
	CAMLlocal2(vprodId, vmes);

	if (!errorCb) return; 
	//	caml_failwith("payment callbacks are not initialized");

	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
	const char *cmes = (*env)->GetStringUTFChars(env, mes, JNI_FALSE);

	vprodId = caml_copy_string(cprodId);
	vmes = caml_copy_string(cmes);

	caml_callback3(errorCb, vprodId, vmes, Val_true);

	CAMLreturn0;
}

static jmethodID gConfirmNotif;

void ml_payment_commit_transaction(value transaction) {
	CAMLparam1(transaction);
	CAMLlocal1(vnotifId);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gConfirmNotif == NULL) {
		gConfirmNotif = (*env)->GetMethodID(env, jViewCls, "confirmNotif", "(Ljava/lang/String;)V");
	}

	vnotifId = Field(transaction, 0);
	jstring jnotifId = (*env)->NewStringUTF(env, String_val(vnotifId));
	(*env)->CallVoidMethod(env, jView, gConfirmNotif, jnotifId);
	(*env)->DeleteLocalRef(env, jnotifId);

	CAMLreturn0;
}

void ml_extractAssets() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jmethodID extractResources = (*env)->GetMethodID(env, jViewCls, "extractAssets", "()V");
	(*env)->CallVoidMethod(env, jView, extractResources);
}

void ml_openURL(value  url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	jstring _url = (*env)->NewStringUTF(env, String_val(url));
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "openURL", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, _url);
}

void ml_addExceptionInfo (value info){
  JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jstring _info = (*env)->NewStringUTF(env, String_val(info));
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlAddExceptionInfo", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, _info);
}

void ml_setSupportEmail (value d){
  JNIEnv *env;
	DEBUG("set support email");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jstring _d = (*env)->NewStringUTF(env, String_val(d));
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlSetSupportEmail", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, _d);
}

value ml_getLocale () {
	JNIEnv *env;
	DEBUG("getLocale");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetLocale", "()Ljava/lang/String;");
	jstring locale = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env,locale,JNI_FALSE);
	value r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env,locale,l);
	//value r = string_of_jstring(env, (*env)->CallObjectMethod(env, jView, meth));
	DEBUGF("getLocale: %s",String_val(r));
  return r;
}

value ml_getStoragePath () {
  JNIEnv *env;
	DEBUG("getStoragePath");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetStoragePath", "()Ljava/lang/String;");
	jstring path = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env, path, JNI_FALSE);
	value r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env, path, l);
	DEBUGF("getStoragePath: %s", String_val(r));
	return r;
}



////////
JNIEXPORT void Java_ru_redspell_lightning_LightView_lightFinalize(JNIEnv *env, jobject jview) {
	DEBUG("handleOnDestroy");
	if (stage) {
		(*env)->DeleteGlobalRef(env,jStorage);
		jStorage = NULL;
		(*env)->DeleteGlobalRef(env,jStorageEditor);
		jStorageEditor = NULL;
		(*env)->DeleteGlobalRef(env,jView);
		jView = NULL;
		__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING","finalize old stage");
		value unload_method = caml_hash_variant("onUnload");
		caml_callback2(caml_get_public_method(stage->stage,unload_method),stage->stage,Val_unit);
		caml_remove_generational_global_root(&stage->stage);
		free(stage);
		caml_callback(*caml_named_value("clear_tweens"),Val_unit);
		DEBUG("tweens clear");
		caml_callback(*caml_named_value("clear_timers"),Val_unit);
		DEBUG("timers clear");
		caml_callback(*caml_named_value("clear_fonts"),Val_unit);
		DEBUG("fonts clear");
		caml_callback(*caml_named_value("texture_cache_clear"),Val_unit);
		DEBUG("texture cache clear");
		caml_callback(*caml_named_value("programs_cache_clear"),Val_unit);
		DEBUG("programs cache clear");
		caml_callback(*caml_named_value("image_program_cache_clear"),Val_unit);
		DEBUG("image programs cache clear");
		payments_destroy();
		// net finalize NEED, but for doodles it's not used
		caml_gc_compaction(Val_unit);
		if (gSndPool != NULL) {
			(*env)->DeleteGlobalRef(env,gSndPool);
			gSndPool = NULL;
			(*env)->DeleteGlobalRef(env,gSndPoolCls);
			gSndPoolCls = NULL;
		};
		render_clear_cached_values ();
		stage = NULL;
	}
}
