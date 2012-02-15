
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
static jobject jStorage;
static jobject jStorageEditor;

typedef enum 
  { 
    St_int_val, 
    St_bool_val, 
    St_string_val, 
  } st_val_type;

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	char *argv[] = {"android",NULL};
	caml_startup(argv);
	gJavaVM = vm;
	__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","caml initialized");
	return JNI_VERSION_1_6; // Check this
}

void android_debug_output(value mtag, value address, value msg) {
	char buf[255];
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else tag = String_val(Field(mtag,0));
	sprintf(buf,"LIGHTNING[%s (%s)]",tag, String_val(address));
	__android_log_write(ANDROID_LOG_DEBUG,buf,String_val(msg));
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
	(*env)->DeleteLocalRef(env, cls); //
	
	if (!mthd) __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Cant find getResource method");
	
	const char * path = String_val(mlpath);
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
	
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","startOffset: %lld, length: %lld (%s)",startOffset,length, String_val(mlpath));
	
	int myfd = dup(fd); 
	lseek(myfd,startOffset,SEEK_SET);
	res->fd = myfd;
	res->length = length;
	
	(*env)->DeleteLocalRef(env, fileDescriptor);
	(*env)->DeleteLocalRef(env, resourceParams);
	(*env)->DeleteLocalRef(env, cls);
	
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
	
	/* 
	 * init storage 
	 */
	 
	jclass viewCls = (*env)->GetObjectClass(env,jView);
	jmethodID getContextMthd = (*env)->GetMethodID(env, viewCls,"getContext","()Landroid/content/Context;");
	jobject contextObj = (*env)->CallObjectMethod(env,jView,getContextMthd);
	
    jclass contextCls = (*env)->GetObjectClass(env, contextObj);
    jmethodID getSharedPreferencesMthd = (*env)->GetMethodID(env, contextCls, "getSharedPreferences", "(Ljava/lang/String;I)Landroid/content/SharedPreferences;");  
    jstring stname = (*env)->NewStringUTF(env, "lightning");
    
    jobject storage = (*env)->CallObjectMethod(env,contextObj, getSharedPreferencesMthd,stname,0);
	jStorage = (*env)->NewGlobalRef(env, storage);

    /* editor */
    jclass storageCls = (*env)->GetObjectClass(env, storage);
    jmethodID jmthd_edit = (*env)->GetMethodID(env, storageCls, "edit", "()Landroid/content/SharedPreferences$Editor;");
    jobject storageEditor = (*env)->CallObjectMethod(env, storage, jmthd_edit);
    jStorageEditor = (*env)->NewGlobalRef(env, storageEditor);
  
      
	(*env)->DeleteLocalRef(env, storage);
	(*env)->DeleteLocalRef(env, stname);
	(*env)->DeleteLocalRef(env, contextCls);
	(*env)->DeleteLocalRef(env, contextObj);
    (*env)->DeleteLocalRef(env, viewCls);
    (*env)->DeleteLocalRef(env, storageCls);
    (*env)->DeleteLocalRef(env, storageEditor);
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


static jobjectArray jarray_of_mlList(JNIEnv* env, value mlList) 
//берет окэмльный список дуплов и делает из него двумерный массив явовый
{
	value block, tuple;
	int flag = 1;
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

	if (ml_url_data == NULL) 
      ml_url_data = caml_named_value("url_data");

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



//////////// key-value storage based on NSUserDefaults

value ml_kv_storage_create() {
  CAMLparam0();
  CAMLreturn((value)jStorage);
}


// commit
void ml_kv_storage_commit(value storage) {
  CAMLparam1(storage);

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
  jmethodID jmthd_commit = (*env)->GetMethodID(env, editorCls, "commit", "()Z");
  (*env)->CallBooleanMethod(env, jStorageEditor, jmthd_commit);
  
  (*env)->DeleteLocalRef(env, editorCls);
  CAMLreturn0;
}



// 
jboolean kv_storage_contains_key(JNIEnv *env, jobject storage, jstring key) {
  jclass storageCls = (*env)->GetObjectClass(env, storage);
  jmethodID jmthd_contains = (*env)->GetMethodID(env, storageCls, "contains", "(Ljava/lang/String;)Z");
  jboolean contains = (*env)->CallBooleanMethod(env, storage, jmthd_contains, key);
  (*env)->DeleteLocalRef(env, storageCls);
  return contains;
} 


value kv_storage_get_val(value storage_ml, value key_ml, st_val_type vtype) {
  CAMLparam2(storage_ml, key_ml);
  CAMLlocal1(tuple);
  
  JNIEnv *env;                                                                                                                                                                                
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);                                                                                                                                   
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {                                                                                                                                 
    __android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");                                                                           
  }   
  
  jobject storage = (jobject)storage_ml;
  jclass  storageCls = (*env)->GetObjectClass(env, storage);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));

  if (!kv_storage_contains_key(env, storage, key)) {
    (*env)->DeleteLocalRef(env, storageCls);
    (*env)->DeleteLocalRef(env, key);
    CAMLreturn(Val_int(0));
  }


  jmethodID jmthd_get;  
  tuple = caml_alloc_tuple(1);
  
  if (vtype == St_string_val) {
    jmthd_get = (*env)->GetMethodID(env, storageCls, "getString", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;");
    jstring defval = (*env)->NewStringUTF(env, "");
    jstring jval = (*env)->CallObjectMethod(env, storage, jmthd_get, key, defval);
    const char * val = (*env)->GetStringUTFChars(env, jval, NULL);
    Store_field(tuple,0,caml_copy_string(val));
    (*env)->ReleaseStringUTFChars(env, jval, val);
    (*env)->DeleteLocalRef(env, defval);
    (*env)->DeleteLocalRef(env, jval);
  } else if (vtype == St_int_val) {
    jmthd_get = (*env)->GetMethodID(env, storageCls, "getInt", "(Ljava/lang/String;I)I");
    jint jval = (*env)->CallIntMethod(env, storage, jmthd_get, key, 0);
    Store_field(tuple,0,Val_int(jval));
  } else {
    jmthd_get = (*env)->GetMethodID(env, storageCls, "getBoolean", "(Ljava/lang/String;Z)Z");
    jboolean jval = (*env)->CallBooleanMethod(env, storage, jmthd_get, key, 0);
    Store_field(tuple,0,Val_bool(jval));
  }
  
  
  (*env)->DeleteLocalRef(env, storageCls);
  (*env)->DeleteLocalRef(env, key);

  CAMLreturn(tuple);
}



// get string
value ml_kv_storage_get_string(value storage, value key_ml) {
  return kv_storage_get_val(storage, key_ml, St_string_val);
}  

// get boolean
value ml_kv_storage_get_bool(value storage, value key_ml) {
  return kv_storage_get_val(storage, key_ml, St_bool_val);
}

// get int 
value ml_kv_storage_get_int(value storage, value key_ml) {
  return kv_storage_get_val(storage, key_ml, St_int_val);
}


void kv_storage_put_val(value storage_ml, value key_ml, value val_ml, st_val_type vtype) {
  CAMLparam3(storage_ml, key_ml, val_ml);

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));
  jmethodID jmthd_put;
  
  if (vtype == St_string_val) {
    jmthd_put = (*env)->GetMethodID(env, editorCls, "putString", "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;");
    jstring val = (*env)->NewStringUTF(env, String_val(val_ml));
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_put, key, val);
    (*env)->DeleteLocalRef(env, val);
  } else if (vtype == St_bool_val) {
    jmthd_put = (*env)->GetMethodID(env, editorCls, "putBoolean", "(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;");
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_put, key, Bool_val(val_ml));
  } else {
    jmthd_put = (*env)->GetMethodID(env, editorCls, "putInt", "(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;");
    (*env)->CallObjectMethod(env, jStorageEditor, jmthd_put, key, Int_val(val_ml));
  }
      
  (*env)->DeleteLocalRef(env, key);
  (*env)->DeleteLocalRef(env, editorCls);
  CAMLreturn0;
}


// put string
void ml_kv_storage_put_string(value storage, value key_ml, value val_ml) {
  return kv_storage_put_val(storage, key_ml, val_ml, St_string_val);
}


void ml_kv_storage_put_bool(value storage, value key_ml, value val_ml) {
  return kv_storage_put_val(storage, key_ml, val_ml, St_bool_val);
}


void ml_kv_storage_put_int(value storage, value key_ml, value val_ml) {
  return kv_storage_put_val(storage, key_ml, val_ml, St_int_val);
}


void ml_kv_storage_remove(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }

  jclass editorCls = (*env)->GetObjectClass(env, jStorageEditor);
  jstring key = (*env)->NewStringUTF(env, String_val(key_ml));
  jmethodID jmthd_remove = (*env)->GetMethodID(env, editorCls, "remove", "(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;");
  jobject e =  (*env)->CallObjectMethod(env, jStorageEditor, jmthd_remove, key);

  (*env)->DeleteLocalRef(env, key);
  (*env)->DeleteLocalRef(env, e);

  CAMLreturn0;
}


value ml_kv_storage_exists(value storage, value key_ml) {
  CAMLparam2(storage, key_ml);

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
  if ((*gJavaVM)->AttachCurrentThread(gJavaVM,&env, 0) < 0) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING","Failed to get the environment using AttachCurrentThread()");
  }


  jstring key = (*env)->NewStringUTF(env, String_val(key_ml)); 
  jboolean contains = kv_storage_contains_key(env, (jobject)storage, key);
  (*env)->DeleteLocalRef(env,key);
  CAMLreturn(Val_bool(contains));
}

