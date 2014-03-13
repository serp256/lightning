#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>

/*#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>*/
#include "mlwrapper_android.h"

static SLObjectItf engineObject = NULL;
static SLEngineItf engineEngine;
static SLObjectItf outputMixObject = NULL;
static SLObjectItf bqPlayerObject = NULL;
static SLPlayItf bqPlayerPlay;
static SLPlayItf fdPlayerPlay;
static SLAndroidSimpleBufferQueueItf bqPlayerBufferQueue;

#define SOUND_ASSERT(cond, mes) if (!cond) caml_raise_with_string(*caml_named_value("Audio_error"), mes);

value ml_alsoundInit() {
	CAMLparam0();


	SLresult r;
	r = slCreateEngine(&engineObject, 0, NULL, 0, NULL, NULL);
	SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot create OpenSLES engine");


    r = (*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot realize OpenSLES engine");


    r = (*engineObject)->GetInterface(engineObject, SL_IID_ENGINE, &engineEngine);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot obtain OpenSLES engine interface");


    r = (*engineEngine)->CreateOutputMix(engineEngine, &outputMixObject, 0, NULL, NULL);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot create OpenSLES output mix");


    r = (*outputMixObject)->Realize(outputMixObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot realize OpenSLES output mix");

    SLDataLocator_AndroidSimpleBufferQueue loc_bufq = {SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 1};
    SLDataFormat_PCM format_pcm = {SL_DATAFORMAT_PCM, 1, SL_SAMPLINGRATE_8, SL_PCMSAMPLEFORMAT_FIXED_16, SL_PCMSAMPLEFORMAT_FIXED_16, SL_SPEAKER_FRONT_CENTER, SL_BYTEORDER_LITTLEENDIAN};
    SLDataSource audioSrc = {&loc_bufq, &format_pcm};
    SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, outputMixObject};
    SLDataSink audioSnk = {&loc_outmix, NULL};

    const SLInterfaceID ids[2] = {SL_IID_BUFFERQUEUE, SL_IID_VOLUME};
    const SLboolean req[2] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
    r = (*engineEngine)->CreateAudioPlayer(engineEngine, &bqPlayerObject, &audioSrc, &audioSnk, 2, ids, req);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannnot create OpenSLES audio player");


    r = (*bqPlayerObject)->Realize(bqPlayerObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot realize OpenSLES audio player");


    r = (*bqPlayerObject)->GetInterface(bqPlayerObject, SL_IID_PLAY, &bqPlayerPlay);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot obtain OpenSLES audio player interface");


    r = (*bqPlayerObject)->GetInterface(bqPlayerObject, SL_IID_BUFFERQUEUE, &bqPlayerBufferQueue);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot obtain OpenSLES buffer queue interface");


    r = (*fdPlayerPlay)->SetPlayState(fdPlayerPlay, SL_PLAYSTATE_PLAYING);
    SOUND_ASSERT(SL_RESULT_SUCCESS == r, "cannot set OpenSLES audio player state");


	CAMLreturn(Val_unit);
}

value ml_alsoundLoad(value vpath) {
	CAMLparam1(vpath);

	resource r;
	SOUND_ASSERT(getResourceFd(String_val(vpath), &r), "cannot load sound");

	void* buf = malloc(r.length);
	read(r.fd, buf, r.length);
	close(r.fd);

	CAMLreturn(Val_int(0));
}

value ml_alsoundPlay(value soundId, value vol, value loop) {}
value ml_alsoundPause(value streamId) {}
value ml_alsoundStop(value streamId) {}
value ml_alsoundSetVolume(value streamId, value vol) {}
value ml_alsoundSetLoop(value streamId, value loop) {}

value ml_avsound_create_player(value vpath) {}
value ml_avsound_playback(value vmp, value vmethodName) {}
value ml_avsound_set_loop(value vmp, value loop) {}
value ml_avsound_set_volume(value vmp, value vol) {}
value ml_avsound_is_playing(value vmp) {}
value ml_avsound_play(value vmp, value cb) {}

/*#include "mlwrapper_android.h"
#include <caml/custom.h>


static jclass gSndPoolCls = NULL;
static jobject gSndPool = NULL;

jclass get_lmp_class() {
	static jclass lmpCls;

	if (!lmpCls) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM,(void**)&env,JNI_VERSION_1_4);	
		lmpCls = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "ru/redspell/lightning/LightMediaPlayer"));
	}

	return lmpCls;
}

value ml_alsoundInit() {
	if (!gSndPool) {
		JNIEnv *env;
		(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

		// jclass amCls = (*env)->FindClass(env, "android/media/AudioManager");
		// jfieldID strmTypeFid = (*env)->GetStaticFieldID(env, amCls, "STREAM_MUSIC", "I");
		// jint strmType = (*env)->GetStaticIntField(env, amCls, strmTypeFid);

		jclass sndPoolCls = (*env)->FindClass(env, "ru/redspell/lightning/LightSoundPool");
		jmethodID mid = (*env)->GetStaticMethodID(env, sndPoolCls, "getInstance", "()Lru/redspell/lightning/LightSoundPool;");
		jobject sndPool = (*env)->CallStaticObjectMethod(env, sndPoolCls, mid);
		// jmethodID constrId = (*env)->GetMethodID(env, sndPoolCls, "<init>", "(III)V");
		// jobject sndPool = (*env)->NewObject(env, sndPoolCls, constrId, 100, strmType, 0);

		gSndPoolCls = (*env)->NewGlobalRef(env, sndPoolCls);
		gSndPool = (*env)->NewGlobalRef(env, sndPool);

		// (*env)->DeleteLocalRef(env, amCls);
		(*env)->DeleteLocalRef(env, sndPoolCls);
		(*env)->DeleteLocalRef(env, sndPool);		
	}
	return Val_unit;
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

value ml_alsoundPause(value streamId) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#pause");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gPauseMthdId == NULL) {
		gPauseMthdId = (*env)->GetMethodID(env, gSndPoolCls, "pause", "(I)V");
	}
 
	(*env)->CallVoidMethod(env, gSndPool, gPauseMthdId, Int_val(streamId));
	return Val_unit;
}

static jmethodID gStopMthdId = NULL;

value ml_alsoundStop(value streamId) {
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
	return Val_unit;
}

static jmethodID gSetVolMthdId = NULL;

value ml_alsoundSetVolume(value streamId, value vol) {
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
	return Val_unit;
}

static jmethodID gSetLoopMthdId = NULL;

value ml_alsoundSetLoop(value streamId, value loop) {
	if (gSndPool == NULL) {
		caml_failwith("alsound is not initialized, try to call Sound.init first, then Sound.load, then channel#setLoop");
	}

	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

	if (gSetLoopMthdId == NULL) {
		gSetLoopMthdId = (*env)->GetMethodID(env, gSndPoolCls, "setLoop", "(II)V");
	}

	(*env)->CallVoidMethod(env, gSndPool, gSetLoopMthdId, Int_val(streamId), Bool_val(loop) ? -1 : 0);	
	return Val_unit;
}

static jmethodID gAutoPause = NULL;
static jmethodID gAutoResume = NULL;

static jmethodID gLmpPauseAll = NULL;
static jmethodID gLmpResumeAll = NULL;



//// Media Player
//
//
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

	if (!createMpMid) createMpMid = (*env)->GetStaticMethodID(env, lmpCls, "createMediaPlayer", "(Ljava/lang/String;)Landroid/media/MediaPlayer;");

	const char* cpath = String_val(vpath);
	jstring jpath = (*env)->NewStringUTF(env, cpath);
	jobject mp = (*env)->CallStaticObjectMethod(env, lmpCls, createMpMid, jpath);

	if (!mp) {
		char mes[255];
		sprintf(mes, "cannot find %s when creating media player", cpath);		
		caml_failwith(mes);
	}

	jobject gmp = (*env)->NewGlobalRef(env, mp);

	(*env)->DeleteLocalRef(env, jpath);
	(*env)->DeleteLocalRef(env, mp);

	retval = caml_alloc_custom(&mpOpts, sizeof(jobject), 0, 1);
	*(jobject*)Data_custom_val(retval) = gmp;

	CAMLreturn(retval);
}


static void inline testMethodId(JNIEnv *env, jclass cls, jmethodID *mid, char* methodName) {
  if (!*mid) {
    *mid = (*env)->GetMethodID(env, cls, methodName, "()V");
  }
}

value ml_avsound_playback(value vmp, value vmethodName) {
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

	return Val_unit;
}

value ml_avsound_set_loop(value vmp, value loop) {
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
	return Val_unit;
}

value ml_avsound_set_volume(value vmp, value vol) {
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

	return Val_unit;
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

value ml_avsound_play(value vmp, value cb) {
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

	return Val_unit;
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
}*/
