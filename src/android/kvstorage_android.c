
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

