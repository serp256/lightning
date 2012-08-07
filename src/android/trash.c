

/* FINALIZER 
JNIEXPORT void Java_ru_redspell_lightning_LightView_lightFinalize(JNIEnv *env, jobject jview) {
	DEBUG("handleOnDestroy");
	if (stage) {
		jfieldID fid = (*env)->GetStaticFieldID(env, jViewCls, "instance", "Lru/redspell/lightning;");
		(*env)->SetStaticObjectField(env, jViewCls, fid, NULL);

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
*/

/*static jclass gContextCls;
static jclass gAssetManagerCls;
static jclass gAssetFdCls;
static jclass gMediaPlayerCls;

static jmethodID gGetContextMid;
static jmethodID gGetAssetsMid;
static jmethodID gOpenFdMid;
static jmethodID gGetFdMid;
static jmethodID gGetOffsetMid;
static jmethodID gGetLenMid;
static jmethodID gMediaPlayerCid;*/

/*void initAvsoundJNI(JNIEnv *env) {
	gContextCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "android/content/Context"));
	gAssetManagerCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "android/content/res/AssetManager"));
	gAssetFdCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "android/content/res/AssetFileDescriptor"));
	gMediaPlayerCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "android/media/MediaPlayer"));

	gGetContextMid = (*env)->GetMethodID(evn, jViewCls, "getContext", "()Landroid/content/Context;");
	gGetAssetsMid = (*env)->GetMethodID(env, contextCls, "getAssets", "()Landroid/content/res/AssetManager;");
	gOpenFdMid = (*env)->GetMethodID(env, assetManagerCls, "openFd", "(Ljava/lang/String;)Landroid/content/res/AssetFileDescriptor;");
	gGetFdMid = (*env)->GetMethodID(env, assetFdCls, "getFileDescriptor", "()Ljava/io/FileDescriptor;");
	gGetOffsetMid = (*env)->GetMethodID(env, assetFdCls, "getStartOffset", "()J");
	gGetLenMid = (*env)->GetMethodID(env, assetFdCls, "getLength", "()J");
	gMediaPlayerCid = (*env)->GetMethodID(env, gMediaPlayerCls, "<init>", "()V");
}*/

