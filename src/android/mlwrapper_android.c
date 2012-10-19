
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <inttypes.h>
#include <pthread.h>
#include <sys/types.h>

#include <caml/custom.h>
#include "mlwrapper.h"
#include "mlwrapper_android.h"
#include "net_curl.h"
#include "assets_extractor.h"
#include "khash.h"

#define caml_acquire_runtime_system()
#define caml_release_runtime_system()

JavaVM *gJavaVM;
jobject jView = NULL;
jclass jViewCls = NULL;

static int ocaml_initialized = 0;
static mlstage *stage = NULL;

/*static jobject jStorage;
static jobject jStorageEditor;*/

static jclass gSndPoolCls = NULL;
static jobject gSndPool = NULL;


typedef enum 
  { 
    St_int_val, 
    St_bool_val, 
    St_string_val, 
  } st_val_type;

typedef struct {
	int32_t offset;
	int32_t size;
	int8_t in_main;
} offset_size_pair_t;  

static void mlUncaughtException(const char* exn, int bc, char** bv) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",exn);
	int i;
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);
	jclass jString = (*env)->FindClass(env,"java/lang/String");
	jobjectArray jbc = (*env)->NewObjectArray(env,bc,jString,NULL);
	for (i = 0; i < bc; i++) {
		if (bv[i]) {
			__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",bv[i]);
			jstring jbve = (*env)->NewStringUTF(env,bv[i]);
			(*env)->SetObjectArrayElement(env,jbc,i,jbve);
			(*env)->DeleteLocalRef(env,jbve);
		};
	};
	// Need to send email with this error and backtrace
	jstring jexn = (*env)->NewStringUTF(env,exn);
	jmethodID mlUncExn = (*env)->GetMethodID(env,jViewCls,"mlUncaughtException","(Ljava/lang/String;[Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env,jView,mlUncExn,jexn,jbc);
	(*env)->DeleteLocalRef(env,jbc);
	(*env)->DeleteLocalRef(env,jexn);
}

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
	//__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING","JNI_OnLoad");
	uncaught_exception_callback = &mlUncaughtException;
	gJavaVM = vm;
	return JNI_VERSION_1_6; // Check this
}

jclass get_lmp_class() {
	static jclass lmpCls;

	if (!lmpCls) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);	
		lmpCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "ru/redspell/lightning/LightMediaPlayer"));
	}

	return lmpCls;
}

/*
static size_t debug_tag_len = 0;
static char *debug_tag = NULL;
static size_t debug_address_len = 0;
static char *debug_address = NULL;
static size_t debug_msg_len = 0;
static char *debug_msg = NULL;
*/

/*
#define COPY_STRING(len,dst,src) \
		if (len < caml_string_length(src)) { \
			len = caml_string_length(src); \
			dst = realloc(dst, len + 1); \
		};\
		memcpy(dst,String_val(src),len);\
		dst[len] = '\0'
*/

void android_debug_output(value mtag, value address, value msg) {
	char *tag;
	if (mtag == Val_int(0)) tag = "DEFAULT";
	else {
		tag = String_val(Field(mtag,0));
		//COPY_STRING(debug_tag_len,debug_tag,Field(mtag,0));
	};
	//COPY_STRING(debug_address_len,debug_address,address);
	//COPY_STRING(debug_msg_len,debug_msg,msg);
//#undef COPY_STRING
	__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s (%s)] %s",tag,String_val(address),String_val(msg)); // this should be APPNAME
	//__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s (%s)] %s",debug_tag,debug_address,debug_msg); // this should be APPNAME
	fprintf(stderr,"%s (%s) %s\n",tag,String_val(address),String_val(msg));
	//__android_log_print(ANDROID_LOG_DEBUG,"LIGHTNING","[%s (%s)] %s","DEFAULT","ADDRESS","MSG"); // this should be APPNAME
	//__android_log_write(ANDROID_LOG_DEBUG,"LIGHTNING",String_val(msg)); // this should be APPNAME
//	fputs(String_val(msg),stderr);
}

void android_debug_output_info(value address,value msg) {
	__android_log_write(ANDROID_LOG_INFO,"LIGHTNING",String_val(msg));
	fprintf(stderr,"INFO (%s) %s\n",String_val(address),String_val(msg));
}

void android_debug_output_warn(value address,value msg) {
	__android_log_write(ANDROID_LOG_WARN,"LIGHTNING",String_val(msg));
	fprintf(stderr,"WARN (%s) %s\n",String_val(address),String_val(msg));
}

void android_debug_output_error(value address, value msg) {
	__android_log_write(ANDROID_LOG_ERROR,"LIGHTNING",String_val(msg));
	fprintf(stderr,"ERROR (%s) %s\n",String_val(address),String_val(msg));
}

void android_debug_output_fatal(value address, value msg) {
	__android_log_write(ANDROID_LOG_FATAL,"LIGHTNING",String_val(msg));
	fprintf(stderr,"FATAL (%s) %s\n",String_val(address),String_val(msg));
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

static char* gAssetsDir;

void ml_setAssetsDir(value vassDir) {
	char* cassDir = String_val(vassDir);
	
	if (gAssetsDir)	{
		free(gAssetsDir);
	}

	gAssetsDir = (char*)malloc(strlen(cassDir) + 1);
	strcpy(gAssetsDir, cassDir);

	//DEBUGF("ml_setAssetsDir %s", gAssetsDir);
}
/*static value assetsExtractedCb;

JNIEXPORT void Java_ru_redspell_lightning_LightView_assetsExtracted(JNIEnv *env, jobject this, jstring assetsDir) {
	(*gJavaVM)->AttachCurrentThread(gJavaVM, &env, 0);

	if (assetsDir != NULL) {
		const char *path = (*env)->GetStringUTFChars(env, assetsDir, JNI_FALSE);
		gAssetsDir = (char*) malloc(strlen(path));
		strcpy(gAssetsDir, path);
		(*env)->ReleaseStringUTFChars(env, assetsDir, path);
	}

	if (!assetsExtractedCb) {
		caml_failwith("assets extracted callback is not initialized");
	}

	caml_callback(assetsExtractedCb, Val_unit);
}*/

KHASH_MAP_INIT_STR(expnsn_index, offset_size_pair_t*);
static kh_expnsn_index_t* idx;

int get_expansion_offset_size_pair(const char* path, offset_size_pair_t** pair) {
	if (!idx) {
		return 1;
	}

	khiter_t k = kh_get(expnsn_index, idx, path);

	if (k == kh_end(idx)) {
		PRINT_DEBUG("%s entry not found in expansions index", path);
		return 1;
	}

	offset_size_pair_t* val = kh_val(idx, k);	
	*pair = val;
	PRINT_DEBUG("%s entry found in expansions index, offset %d, size %d", path, val->offset, val->size);

	return 0;
}

// NEED rewrite it for libzip
int getResourceFd(const char *path, resource *res) { //{{{
	//DEBUGF("getResourceFD: %s",path);
	offset_size_pair_t* os_pair;

	if (!get_expansion_offset_size_pair(path, &os_pair)) {
		char* expnsn_path = get_expansion_path(os_pair->in_main);

		int fd = open(expnsn_path, O_RDONLY);
		if (fd < 0) return 0;
		lseek(fd, os_pair->offset, SEEK_SET);
		
		res->fd = fd;
		res->length = os_pair->size;

		free(expnsn_path);
	} else
		if (gAssetsDir != NULL) {
			int assetsDirLen = strlen(gAssetsDir);
			int pathLen = strlen(path);

			char *assetPath = (char*)malloc(assetsDirLen + pathLen + 1);
			strcpy(assetPath, gAssetsDir);
			strcpy(assetPath + assetsDirLen, path);

			//DEBUGF("assetPath: %s", assetPath);

			int fd = open(assetPath, O_RDONLY);

			if (fd < 0) {
				PRINT_DEBUG("%s not found in extracted assets", path);
				return 0;
			}

			PRINT_DEBUG("%s found in extracted assets", path);
			free(assetPath);

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
	PRINT_DEBUG("lightInit");

	jView = (*env)->NewGlobalRef(env,jview);

	jclass viewCls = (*env)->GetObjectClass(env, jView);
	jViewCls = (*env)->NewGlobalRef(env, viewCls);

	
	/* shared preferences 
	jStorage = (*env)->NewGlobalRef(env, storage);
	jclass storageCls = (*env)->GetObjectClass(env, storage);
	jmethodID jmthd_edit = (*env)->GetMethodID(env, storageCls, "edit", "()Landroid/content/SharedPreferences$Editor;");
	jobject storageEditor = (*env)->CallObjectMethod(env, storage, jmthd_edit);
	jStorageEditor = (*env)->NewGlobalRef(env, storageEditor);
	(*env)->DeleteLocalRef(env, storageCls);
	(*env)->DeleteLocalRef(env, storageEditor);*/
	(*env)->DeleteLocalRef(env, viewCls);
}


JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceCreated(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("lightRender init");
	if (!ocaml_initialized) {
		PRINT_DEBUG("init ocaml");
		char *argv[] = {"android",NULL};
		caml_startup(argv);
		ocaml_initialized = 1;
		PRINT_DEBUG("caml initialized");
	};
	if (stage) return;
	PRINT_DEBUG("create stage: [%d:%d]",width,height);
	stage = mlstage_create((float)width,(float)height); 
	PRINT_DEBUG("stage created");
}

static int onResume = 0;

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeSurfaceChanged(JNIEnv *env, jobject jrenderer, jint width, jint height) {
	PRINT_DEBUG("GL Changed: %i:%i",width,height);

	if (onResume) {
		onResume = 0;
		static value dispatchFgHandler = 1;

		if (stage) {
			if (dispatchFgHandler == 1) dispatchFgHandler = caml_hash_variant("dispatchForegroundEv");
			caml_callback2(caml_get_public_method(stage->stage, dispatchFgHandler), stage->stage, Val_unit);
		}
	}
}



static value run_method = 1;//None
//void mlstage_run(double timePassed) {
//}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_nativeDrawFrame(JNIEnv *env, jobject thiz, jlong interval) {
	CAMLparam0();
	CAMLlocal1(timePassed);
	timePassed = caml_copy_double((double)interval / 1000000000L);
	//mlstage_run(timePassed);
	if (net_running > 0) net_perform();
	if (run_method == 1) run_method = caml_hash_variant("run");
	caml_callback2(caml_get_public_method(stage->stage,run_method),stage->stage,timePassed);
	// PRINT_DEBUG("caml run ok");
	CAMLreturn0;
}


// Touches 

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_fireTouch(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y, jint phase) {
	CAMLparam0();
	CAMLlocal3(globalX,globalY,touch);
	value touches = 1;
	touch = caml_alloc_tuple(8);
	globalX = caml_copy_double(x);
	globalY = caml_copy_double(y);
	Store_field(touch,0,caml_copy_int32(id + 1));
	Store_field(touch,1,caml_copy_double(0.));
	Store_field(touch,2,globalX);
	Store_field(touch,3,globalY);
	Store_field(touch,4,globalX);
	Store_field(touch,5,globalY);
	Store_field(touch,6,Val_int(1));// tap_count
	Store_field(touch,7,Val_int(phase)); 
	touches = caml_alloc_small(2,0);
	Field(touches,0) = touch;
	Field(touches,1) = 1; // None
  mlstage_processTouches(stage,touches);
	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_fireTouches(JNIEnv *env, jobject thiz, jintArray jids, jfloatArray jxs, jfloatArray jys, jintArray jphases) {
	CAMLparam0();
	CAMLlocal5(touch,touches,globalX,globalY,timestamp);
	int size = (*env)->GetArrayLength(env,jids);
	jint ids[size];
	jfloat xs[size];
	jfloat ys[size];
	jint phases[size];
	(*env)->GetIntArrayRegion(env,jids,0,size,ids);
	(*env)->GetFloatArrayRegion(env,jxs,0,size,xs);
	(*env)->GetFloatArrayRegion(env,jys,0,size,ys);
	(*env)->GetIntArrayRegion(env,jphases,0,size,phases);
	value lst_el;
	int i = 0;
	touches = 1;
	timestamp = caml_copy_double(0.);
	for (i = 0; i < size; i++) {
		if (phases[i] != 2) {
			PRINT_DEBUG("touch with coord: %f:%f",xs[i],ys[i]);
			globalX = caml_copy_double(xs[i]);
			globalY = caml_copy_double(ys[i]);
			touch = caml_alloc_tuple(8);
			Store_field(touch,0,caml_copy_int32(ids[i] + 1));
			Store_field(touch,1,timestamp);
			Store_field(touch,2,globalX);
			Store_field(touch,3,globalY);
			Store_field(touch,4,globalX);
			Store_field(touch,5,globalY);
			Store_field(touch,6,Val_int(1));// tap_count
			Store_field(touch,7,Val_int(phases[i]));
			lst_el = caml_alloc_small(2,0);
			Field(lst_el,0) = touch;
			Field(lst_el,1) = touches;
			touches = lst_el;
		}
	}
  mlstage_processTouches(stage,touches);
	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_cancelAllTouches() {
	mlstage_cancelAllTouches(stage);
}

/*
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
*/

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

	jclass lmpCls = get_lmp_class();

	if (gGetSndIdMthdId == NULL) {
		gGetSndIdMthdId = (*env)->GetStaticMethodID(env, lmpCls, "getSoundId", "(Ljava/lang/String;Landroid/media/SoundPool;)I");
	}

	char* cpath = String_val(path);
	jstring jpath = (*env)->NewStringUTF(env, cpath);
	jint sndId = (*env)->CallStaticIntMethod(env, lmpCls, gGetSndIdMthdId, jpath, gSndPool);

	if (sndId < 0) {
		char mes[255];
		sprintf(mes, "cannot find %s when adding to sound pool", cpath);
		caml_failwith(mes);
	}

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

	PRINT_DEBUG("ml_alsoundStop call %d", Int_val(streamId));
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

static jmethodID gLmpPauseAll = NULL;
static jmethodID gLmpResumeAll = NULL;

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnPause(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnPause call");

	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		if (gAutoPause == NULL) {
			gAutoPause = (*env)->GetMethodID(env, gSndPoolCls, "autoPause", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoPause);
	}

	jclass lmpCls = get_lmp_class();

	if (gLmpPauseAll == NULL) {
		gLmpPauseAll = (*env)->GetStaticMethodID(env, lmpCls, "pauseAll", "()V");
	}

	(*env)->CallStaticVoidMethod(env, lmpCls, gLmpPauseAll);

	static value dispatchBgHandler = 1;

	if (stage) {
		if (dispatchBgHandler == 1) dispatchBgHandler = caml_hash_variant("dispatchBackgroundEv");
		caml_callback2(caml_get_public_method(stage->stage, dispatchBgHandler), stage->stage, Val_unit);
	}	
}

JNIEXPORT void Java_ru_redspell_lightning_LightRenderer_handleOnResume(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightRenderer_handleOnResume call");

	if (gSndPool != NULL) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
		
		if (gAutoResume == NULL) {
			gAutoResume = (*env)->GetMethodID(env, gSndPoolCls, "autoResume", "()V");
		}

		(*env)->CallVoidMethod(env, gSndPool, gAutoResume);
	}

	jclass lmpCls = get_lmp_class();

	if (gLmpResumeAll == NULL) {
		gLmpResumeAll = (*env)->GetStaticMethodID(env, lmpCls, "resumeAll", "()V");
	}

	PRINT_DEBUG("resume ALL players");
	(*env)->CallStaticVoidMethod(env, lmpCls, gLmpResumeAll);

	onResume = 1;
}

/* Updated upstream
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
		char* cpubkey = String_val(Field(pubkey, 0));
		jstring jpubkey = (*env)->NewStringUTF(env, cpubkey);

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

	char* cprodId = String_val(prodId);
	jstring jprodId = (*env)->NewStringUTF(env, cprodId);
	(*env)->CallVoidMethod(env, jView, gRequestPurchase, jprodId);

	(*env)->DeleteLocalRef(env, jprodId);
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb(JNIEnv *env, jobject this, jstring prodId, jstring notifId, jstring signedData, jstring signature) {
	CAMLparam0();
	CAMLlocal2(tr, vprodId);

	DEBUGF("Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentSuccessCb %d", gettid());

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

	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
	(*env)->ReleaseStringUTFChars(env, notifId, cnotifId);
	(*env)->ReleaseStringUTFChars(env, signature, csignature);
	(*env)->ReleaseStringUTFChars(env, signedData, csignedData);

	DEBUG("return jni invoke caml payment succ cb");

	CAMLreturn0;
}

JNIEXPORT void Java_ru_redspell_lightning_payments_BillingService_invokeCamlPaymentErrorCb(JNIEnv *env, jobject this, jstring prodId, jstring mes) {
	DEBUG("jni invoke caml payment error cb");

	CAMLparam0();
	CAMLlocal2(vprodId, vmes);

	if (!errorCb) return; 
	//	caml_failwith("payment callbacks are not initialized");

	const char *cprodId = (*env)->GetStringUTFChars(env, prodId, JNI_FALSE);
	const char *cmes = (*env)->GetStringUTFChars(env, mes, JNI_FALSE);

	vprodId = caml_copy_string(cprodId);
	vmes = caml_copy_string(cmes);

	caml_callback3(errorCb, vprodId, vmes, Val_true);

	(*env)->ReleaseStringUTFChars(env, prodId, cprodId);
	(*env)->ReleaseStringUTFChars(env, mes, cmes);

	DEBUG("return jni invoke caml payment err cb");

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
	char* cnotifId = String_val(vnotifId);
	jstring jnotifId = (*env)->NewStringUTF(env, cnotifId);
	(*env)->CallVoidMethod(env, jView, gConfirmNotif, jnotifId);

	(*env)->DeleteLocalRef(env, jnotifId);

	CAMLreturn0;
}
*/


void ml_openURL(value  url) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	char* curl = String_val(url);
	jstring jurl = (*env)->NewStringUTF(env, curl);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "openURL", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jurl);

	(*env)->DeleteLocalRef(env, jurl);
}

void ml_addExceptionInfo (value info){
  	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cinfo = String_val(info);
	jstring jinfo = (*env)->NewStringUTF(env, cinfo);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlAddExceptionInfo", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jinfo);

	(*env)->DeleteLocalRef(env, jinfo);
}

void ml_setSupportEmail (value d){
  JNIEnv *env;
	DEBUG("DDD: set support email");
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	char* cd = String_val(d);
	jstring jd = (*env)->NewStringUTF(env, cd);
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "mlSetSupportEmail", "(Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env, jView, mid, jd);

	(*env)->DeleteLocalRef(env, jd);	
}

value ml_getLocale () {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetLocale", "()Ljava/lang/String;");
	jstring locale = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env,locale,JNI_FALSE);
	value r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env, locale, l);
	(*env)->DeleteLocalRef(env, locale);
	//value r = string_of_jstring(env, (*env)->CallObjectMethod(env, jView, meth));
  return r;
}

value ml_getStoragePath () {

	CAMLparam0();
	CAMLlocal1(r);

  	JNIEnv *env;	
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID meth = (*env)->GetMethodID(env, jViewCls, "mlGetStoragePath", "()Ljava/lang/String;");
	jstring path = (*env)->CallObjectMethod(env, jView, meth);
	const char *l = (*env)->GetStringUTFChars(env, path, JNI_FALSE);

	r = caml_copy_string(l);
	(*env)->ReleaseStringUTFChars(env, path, l);
	(*env)->DeleteLocalRef(env, path);


	CAMLreturn(r);
}


static void mp_finalize(value vmp) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID releaseMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!releaseMid) {
		releaseMid = (*env)->GetMethodID(env, mpCls, "release", "()V"); 
	}

	(*env)->CallVoidMethod(env, jmp, releaseMid);
	(*env)->DeleteLocalRef(env, mpCls);
	(*env)->DeleteGlobalRef(env, jmp);
}

struct custom_operations mpOpts = {
	"pointer to MediaPlayer",
	mp_finalize,
	custom_compare_default,
	custom_hash_default,
	custom_serialize_default,
	custom_deserialize_default
};

value ml_avsound_create_player(value vpath) {
	CAMLparam1(vpath);
	CAMLlocal1(retval);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID createMpMid;
	jclass lmpCls = get_lmp_class();

	if (!createMpMid) createMpMid = (*env)->GetStaticMethodID(env, lmpCls, "createMediaPlayer", "(Ljava/lang/String;Ljava/lang/String;)Landroid/media/MediaPlayer;");

	const char* cpath = String_val(vpath);
	jstring jpath = (*env)->NewStringUTF(env, cpath);
	jstring jassetsDir = NULL;

	if (gAssetsDir) {
		jassetsDir = (*env)->NewStringUTF(env, gAssetsDir);		
	}

	jobject mp = (*env)->CallStaticObjectMethod(env, lmpCls, createMpMid, jassetsDir, jpath);

	if (!mp) {
		char mes[255];
		sprintf(mes, "cannot find %s when creating media player", cpath);		
		caml_failwith(mes);
	}

	jobject gmp = (*env)->NewGlobalRef(env, mp);

	if (jassetsDir) {
		(*env)->DeleteLocalRef(env, jassetsDir);
	}

	(*env)->DeleteLocalRef(env, jpath);
	(*env)->DeleteLocalRef(env, mp);

	retval = caml_alloc_custom(&mpOpts, sizeof(jobject), 0, 1);
	*(jobject*)Data_custom_val(retval) = gmp;

	CAMLreturn(retval);
}

void testMethodId(JNIEnv *env, jclass cls, jmethodID *mid, char* methodName) {
	DEBUGF("testMethodId %s", methodName);
	if (!*mid) {
		DEBUGF("call %s", methodName);

		*mid = (*env)->GetMethodID(env, cls, methodName, "()V");
		//DEBUG("GetMethodID call");
	}
}

void ml_avsound_playback(value vmp, value vmethodName) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID pauseMid;
	static jmethodID stopMid;
	static jmethodID prepareMid;

	char* methodName = String_val(vmethodName);

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);
	jmethodID *mid;

	do {
		if (!strcmp(methodName, "stop")) {
			mid = &stopMid;
			break;
		}

		if (!strcmp(methodName, "pause")) {
			mid = &pauseMid;
			break;
		}

		if (!strcmp(methodName, "prepare")) {
			mid = &prepareMid;
			break;
		}
	} while(0);

	testMethodId(env, mpCls, mid, methodName);
	(*env)->CallVoidMethod(env, jmp, *mid);
	(*env)->DeleteLocalRef(env, mpCls);
}

void ml_avsound_set_loop(value vmp, value loop) {
	PRINT_DEBUG("!!!ml_avsound_set_loop call");

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID setLoopMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!setLoopMid) {
		setLoopMid = (*env)->GetMethodID(env, mpCls, "setLooping", "(Z)V");		
	}

	(*env)->CallVoidMethod(env, jmp, setLoopMid, Bool_val(loop));
	(*env)->DeleteLocalRef(env, mpCls);
}

void ml_avsound_set_volume(value vmp, value vol) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID setLoopMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!setLoopMid) {
		setLoopMid = (*env)->GetMethodID(env, mpCls, "setVolume", "(FF)V");
	}

	double cvol = Double_val(vol);
	(*env)->CallVoidMethod(env, jmp, setLoopMid, cvol, cvol);
	(*env)->DeleteLocalRef(env, mpCls);
}

value ml_avsound_is_playing(value vmp) {
	CAMLparam1(vmp);
	CAMLlocal1(retval);

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID isPlayingMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!isPlayingMid) {
		isPlayingMid = (*env)->GetMethodID(env, mpCls, "isPlaying", "()Z");
	}

	//DEBUGF("ml_avsound_is_playing %s", (*env)->CallBooleanMethod(env, jmp, isPlayingMid) ? "true" : "false");

	retval = Val_bool((*env)->CallBooleanMethod(env, jmp, isPlayingMid));
	(*env)->DeleteLocalRef(env, mpCls);

	CAMLreturn(retval);
}

void ml_avsound_play(value vmp, value cb) {
	PRINT_DEBUG("ml_avsound_play tid: %d", gettid());

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID playMid;

	jobject jmp = *(jobject*)Data_custom_val(vmp);
	jclass mpCls = (*env)->GetObjectClass(env, jmp);

	if (!playMid) {
		playMid = (*env)->GetMethodID(env, mpCls, "start", "(I)V");
	}

	value *cbptr = malloc(sizeof(value));
	*cbptr = cb;
	caml_register_generational_global_root(cbptr);

	(*env)->CallVoidMethod(env, jmp, playMid, (jint)cbptr);
	(*env)->DeleteLocalRef(env, mpCls);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightMediaPlayer_00024CamlCallbackCompleteRunnable_run(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_LightMediaPlayer_00024CamlCallbackCompleteRunnable_run tid: %d", gettid());

	jclass runnableCls = (*env)->GetObjectClass(env, this);
	static jfieldID cbFid;

	if (!cbFid) {
		cbFid = (*env)->GetFieldID(env, runnableCls, "cb", "I");
	}

	value *cbptr = (value*)(*env)->GetIntField(env, this, cbFid);
	value cb = *cbptr;
	caml_callback(cb, Val_unit);
	caml_remove_generational_global_root(cbptr);

	(*env)->DeleteLocalRef(env, runnableCls);
}

static value ml_dispatchBackHandler = 1;

JNIEXPORT jboolean JNICALL Java_ru_redspell_lightning_LightRenderer_handleBack(JNIEnv *env, jobject this) {
	if (stage) {
		if (ml_dispatchBackHandler == 1) {
			ml_dispatchBackHandler = caml_hash_variant("dispatchBackPressedEv");
		}

		value res = caml_callback2(caml_get_public_method(stage->stage, ml_dispatchBackHandler), stage->stage, Val_unit);
		if (Bool_val(res)) exit(0);
	}

	return 1;
}

static value version;

value ml_getVersion() {
	// DEBUG("ml_getVersion");

	if (!version) {
		// DEBUG("!version");
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getVersion", "()Ljava/lang/String;");
		jstring jver = (*env)->CallObjectMethod(env, jView, mid);
		const char* cver = (*env)->GetStringUTFChars(env, jver, JNI_FALSE);

		// DEBUGF("cver %s", cver);

		version = caml_copy_string(cver);
		caml_register_generational_global_root(&version);

		(*env)->ReleaseStringUTFChars(env, jver, cver);
		(*env)->DeleteLocalRef(env, jver);
	}

	return version;
}


void ml_tapjoy_init(value ml_appID,value ml_secretKey) {
	DEBUG("init tapjoy");
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
	jstring appID = (*env)->NewStringUTF(env,String_val(ml_appID));
	jstring secretKey = (*env)->NewStringUTF(env,String_val(ml_secretKey));
	static jmethodID initTapjoyMethod = 0;
	if (initTapjoyMethod == 0) initTapjoyMethod = (*env)->GetMethodID(env,jViewCls,"initTapjoy","(Ljava/lang/String;Ljava/lang/String;)V");
	(*env)->CallVoidMethod(env,jView,initTapjoyMethod,appID,secretKey);
}

static jclass gTapjoyCls;
static jobject gTapjoy;

void getTapjoyJNI() {
	if (!gTapjoyCls) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jclass tapjoyCls = (*env)->FindClass(env, "com/tapjoy/TapjoyConnect");
		jmethodID mid = (*env)->GetStaticMethodID(env, tapjoyCls, "getTapjoyConnectInstance", "()Lcom/tapjoy/TapjoyConnect;");
		jobject tapjoy = (*env)->CallStaticObjectMethod(env, tapjoyCls, mid);

		gTapjoyCls = (*env)->NewGlobalRef(env, tapjoyCls);
		gTapjoy = (*env)->NewGlobalRef(env, tapjoy);

		(*env)->DeleteLocalRef(env, tapjoyCls);
		(*env)->DeleteLocalRef(env, tapjoy);
	}
}

void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jstring jcurrency = (*env)->NewStringUTF(env, String_val(currency));
	jboolean jshow_selector = Bool_val(show_selector);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffersWithCurrencyID", "(Ljava/lang/String;Z)V");
	}

	(*env)->CallVoidMethod(env, gTapjoy, mid, jcurrency, jshow_selector);
	(*env)->DeleteLocalRef(env, jcurrency);
}

void ml_tapjoy_show_offers() {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "showOffers", "()V");
	}

	(*env)->CallVoidMethod(env, gTapjoy, mid);
}

void ml_tapjoy_set_user_id(value uid) {
	getTapjoyJNI();

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;

	if (!mid) {
		mid = (*env)->GetMethodID(env, gTapjoyCls, "setUserID", "(Ljava/lang/String;)V");
	}

	jstring juid = (*env)->NewStringUTF(env, String_val(uid));
	(*env)->CallVoidMethod(env, gTapjoy, mid, juid);
	(*env)->DeleteLocalRef(env, juid);
}

static value device_id;

value ml_device_id(value unit) {
	/*DEBUGF("ML_DEVICE_ID");*/
	if (!device_id) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "device_id", "()Ljava/lang/String;");
		jstring jdev = (*env)->CallObjectMethod(env, jView, mid);
		const char* cdev = (*env)->GetStringUTFChars(env, jdev, JNI_FALSE);

		device_id = caml_copy_string(cdev);
		caml_register_generational_global_root(&device_id);

		(*env)->ReleaseStringUTFChars(env, jdev, cdev);
		(*env)->DeleteLocalRef(env, jdev);
	}

	return device_id;
}

static value andrScreen;

#define ANDR_SMALL_W 320
#define ANDR_SMALL_H 426
#define ANDR_NORMAL_W 320
#define ANDR_NORMAL_H 470
#define ANDR_LARGE_W 480
#define ANDR_LARGE_H 640
#define ANDR_XLARGE_W 720
#define ANDR_XLARGE_H 960

value ml_androidScreen() {
	if (!andrScreen) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);
		
		jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getScreenWidth", "()I");
		int w = (int)(*env)->CallIntMethod(env, jView, mid);
		mid = (*env)->GetMethodID(env, jViewCls, "getScreenHeight", "()I");
		int h = (int)(*env)->CallIntMethod(env, jView, mid);
		mid = (*env)->GetMethodID(env, jViewCls, "getDensity", "()I");
		int d = (int)(*env)->CallIntMethod(env, jView, mid);

		if (w > h) {
			w = w ^ h;
			h = w ^ h;
			w = w ^ h;
		}

		value screen = 0;
		value density = 0;

		switch (d) {
			case 120:
				density = Val_int(0);
				break;

			case 160:
				density = Val_int(1);
				break;

			case 240:
				density = Val_int(2);
				break;

			case 320:
				density = Val_int(3);
				break;
		}

		PRINT_DEBUG("android screen %d %d %d", w, h, d);

		if (w == 600 && h == 1024) {
			if (d == 240) {
				screen = Val_int(1);
			} else if (d == 160) {
				screen = Val_int(2);
			} else if (d == 120) {
				screen = Val_int(3);
			}
		} else {
			float dpw = (float)w / ((float)d / 160);
			float dph = (float)h / ((float)d / 160);

			PRINT_DEBUG("dpw, dph: %f; %f", dpw, dph);

			if (ANDR_SMALL_W <= dpw && dpw <= ANDR_NORMAL_W && ANDR_SMALL_H <= dph && dph <= ANDR_NORMAL_H) {
				PRINT_DEBUG("small");
				screen = Val_int(0);
			} else if (ANDR_NORMAL_W <= dpw && dpw <= ANDR_LARGE_W  && ANDR_NORMAL_H <= dph && dph <= ANDR_LARGE_H) {
				PRINT_DEBUG("normal");
				screen = Val_int(1);
			} else if (ANDR_LARGE_W <= dpw && dpw <= ANDR_XLARGE_W && ANDR_LARGE_H <= dph && dph <= ANDR_XLARGE_H) {
				PRINT_DEBUG("large");
				screen = Val_int(2);
			} else if (ANDR_XLARGE_W <= dpw && ANDR_XLARGE_H <= dph) {
				PRINT_DEBUG("xlarge");
				screen = Val_int(3);
			}			
		}

		if (!screen || !density) {
			PRINT_DEBUG("none");
			andrScreen = Val_int(0);
		} else {
			PRINT_DEBUG("some");

			value tuple = caml_alloc(2, 0);
			andrScreen = caml_alloc(1, 0);

			Store_field(tuple, 0, screen);
			Store_field(tuple, 1, density);
			Store_field(andrScreen, 0, tuple);
		}
	}

	return andrScreen;
}

value ml_device_type(value unit) {
	DEBUGF("ML_DEVICE_TYPE");
	CAMLparam0();
	CAMLlocal1(retval);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "isTablet", "()Z");
	jboolean jres = (*env)->CallBooleanMethod(env, jView, mid);

	if (jres) {
		retval = Val_int(1);
	} else {
		retval = Val_int(0);
	};
	//(*env)->DeleteLocalRef(env, jres);
	CAMLreturn(retval);
}


/*
void ml_test_c_fun(value fun) {
	caml_callback(fun,Val_unit);
}*/

#define CAML_FAILWITH(...) {																			\
	char* err_mes = (char*)malloc(255);																	\
	sprintf(err_mes, __VA_ARGS__);																		\
	jmethodID mid = (*env)->GetMethodID(env, jViewCls, "camlFailwith", "(Ljava/lang/String;)V");		\
	jstring jerrMes = (*env)->NewStringUTF(env, err_mes);												\
	(*env)->CallVoidMethod(env, jView, mid, jerrMes);													\
	(*env)->DeleteLocalRef(env, jerrMes);																\
	free(err_mes);																						\
	pthread_exit(NULL);																					\
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024CamlFailwithRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID errMesFid;

	if (!errMesFid) {
		jclass selfCls = (*env)->GetObjectClass(env, this);
		errMesFid = (*env)->GetFieldID(env, selfCls, "errMes", "Ljava/lang/String;");
		(*env)->DeleteLocalRef(env, selfCls);
	}

	jstring jerrMes = (*env)->GetObjectField(env, this, errMesFid);
	const char* cerrMes = (*env)->GetStringUTFChars(env, jerrMes, JNI_FALSE);
	//value verrMes = caml_copy_string(cerrMes);

	(*env)->ReleaseStringUTFChars(env, jerrMes, cerrMes);
	(*env)->DeleteLocalRef(env, jerrMes);
	
	caml_failwith(cerrMes);
}

void* extract_expansions_thread(void* params) {
    JNIEnv *env;
    (*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);

	idx = kh_init_expnsn_index();
	char* expnsn_path = get_expansion_path(0);

	FILE* in = fopen(expnsn_path, "r");
	if (!in) CAML_FAILWITH("cannot open expansions file %s", expnsn_path);

	int32_t index_entries_num;		
	if (1 != fread(&index_entries_num, sizeof(int32_t), 1, in)) CAML_FAILWITH("cannot ready expansions index entries number");

	int i = 0;
	khiter_t k;
	offset_size_pair_t* pair;

	while (i++ < index_entries_num) {
		int8_t filename_len;
		if (1 != fread(&filename_len, sizeof(int8_t), 1, in)) CAML_FAILWITH("cannot read filename length for index entry %d", i - 1);

		char* filename = malloc(filename_len + 1);
		int32_t offset;
		int32_t size;
		int8_t in_main;

		if (filename_len != fread(filename, 1, filename_len, in)) CAML_FAILWITH("cannot read filename for entry %d", i - 1);
		*(filename + filename_len) = '\0';
		if (1 != fread(&offset, sizeof(int32_t), 1, in)) CAML_FAILWITH("cannot read offset for entry %d", i - 1);
		if (1 != fread(&size, sizeof(int32_t), 1, in)) CAML_FAILWITH("cannot read size for entry %d", i - 1);
		if (1 != fread(&in_main, sizeof(int8_t), 1, in)) CAML_FAILWITH("cannot read in_main flag for entry %d", i - 1);

		int ret;
		pair = (offset_size_pair_t*)malloc(sizeof(offset_size_pair_t));
		pair->offset = offset;
		pair->size = size;
		pair->in_main = in_main;

		k = kh_put(expnsn_index, idx, filename, &ret);
		kh_val(idx, k) = pair;

		PRINT_DEBUG("filename: %s; offset: %d; size: %d; in_main %d\n", filename, offset, size, in_main);
	}

	long files_begin_pos = ftell(in);
	fclose(in);
	free(expnsn_path);

    for (k = kh_begin(idx); k != kh_end(idx); ++k)
        if (kh_exist(idx, k)) {
        	pair = kh_val(idx, k);
        	pair->offset = pair->offset + (pair->in_main ? 0 : files_begin_pos);
        }

    static jmethodID callExpansionsCompleteMid;

    if (!callExpansionsCompleteMid) {
        callExpansionsCompleteMid = (*env)->GetMethodID(env, jViewCls, "callExpansionsComplete", "(I)V");
    }

    (*env)->CallVoidMethod(env, jView, callExpansionsCompleteMid, (int)params);
    (*gJavaVM)->DetachCurrentThread(gJavaVM);

    pthread_exit(NULL);    
	//caml_callback(cb, Val_bool(1));
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExpansionsCallbackRunnable_run(JNIEnv *env, jobject this) {
	static jfieldID cbFid;

	if (!cbFid) {
		jclass selfCls = (*env)->GetObjectClass(env, this);
		cbFid = (*env)->GetFieldID(env, selfCls, "cb", "I");
		(*env)->DeleteLocalRef(env, selfCls);
	}

	value* cb = (value*)(*env)->GetIntField(env, this, cbFid);
	caml_callback(*cb, Val_bool(1));
	caml_remove_generational_global_root(cb);
}

void ml_extractExpansions(value cb) {
	if (idx) {
		caml_callback(cb, Val_bool(1));
		return;
	}

    pthread_t tid;

    value* params = (value*)malloc(sizeof(value));
    *params = cb;
    caml_register_generational_global_root(params);

    if (pthread_create(&tid, NULL, extract_expansions_thread, (void*) params)) {
        PRINT_DEBUG("cannot create extract expansions thread");
    }	
}

value ml_expansionExtracted() {
	return Val_bool(idx);
}

JNIEXPORT jobject JNICALL Java_ru_redspell_lightning_LightMediaPlayer_getOffsetSizePair(JNIEnv *env, jobject this, jstring path) {
	offset_size_pair_t* pair;
	const char* cpath = (*env)->GetStringUTFChars(env, path, JNI_FALSE);
	jobject retval = NULL;

	if (!get_expansion_offset_size_pair(cpath, &pair)) {
		static jclass offsetSizePairCls;
		static jmethodID offsetSizePairConstrMid;

		if (!offsetSizePairConstrMid) {
			jclass _offsetSizePairCls = (*env)->FindClass(env, "ru/redspell/lightning/LightMediaPlayer$OffsetSizePair");
			offsetSizePairCls = (*env)->NewGlobalRef(env, _offsetSizePairCls);
			(*env)->DeleteLocalRef(env, _offsetSizePairCls);
			offsetSizePairConstrMid = (*env)->GetMethodID(env, offsetSizePairCls, "<init>", "(III)V");
		}

		retval = (*env)->NewObject(env, offsetSizePairCls, offsetSizePairConstrMid, (jint)pair->offset, (jint)pair->size, (jint)pair->in_main);
	}

	(*env)->ReleaseStringUTFChars(env, path, cpath);
	return retval;
}

value ml_platform() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "platform", "()Ljava/lang/String;");

	jstring jplat = (*env)->CallStaticObjectMethod(env, jView, mid);
	const char* cplat = (*env)->GetStringUTFChars(env, jplat, JNI_FALSE);
	value retval = caml_copy_string(cplat);

	(*env)->ReleaseStringUTFChars(env, jplat, cplat);
	(*env)->DeleteLocalRef(env, jplat);

	return retval;
}

value ml_hwmodel() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "hwmodel", "()Ljava/lang/String;");

	jstring jmodel = (*env)->CallStaticObjectMethod(env, jView, mid);
	const char* cmodel = (*env)->GetStringUTFChars(env, jmodel, JNI_FALSE);
	value retval = caml_copy_string(cmodel);

	(*env)->ReleaseStringUTFChars(env, jmodel, cmodel);
	(*env)->DeleteLocalRef(env, jmodel);

	return retval;
}

value ml_totalMemory() {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void **)&env, JNI_VERSION_1_4);

	static jmethodID mid;
	if (!mid) mid = (*env)->GetStaticMethodID(env, jViewCls, "totalMemory", "()J");
	jlong jtotalmem = (*env)->CallStaticLongMethod(env, jView, mid);

	return Val_long(jtotalmem);
}
