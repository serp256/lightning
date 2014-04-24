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

typedef struct {
	void *buf;
	int len;
} alsound_t;

typedef struct {
	int id;
	SLObjectItf bqPlayerObject;
	SLPlayItf bqPlayerPlay;
	SLAndroidSimpleBufferQueueItf bqPlayerBufferQueue;
	SLVolumeItf bqPlayerVolume;
	uint8_t in_usage;
	uint8_t looped;
	alsound_t *sound;
	value callback;
} bq_player_t;

bq_player_t **bq_players = NULL;
uint8_t bq_players_num = 0;

#define SOUND_ASSERT(cond, mes) if (cond) {} else caml_raise_with_string(*caml_named_value("Audio_error"), mes);
#define ATTENUATION(vol) (100 - Int_val(vol)) * -35

void free_bq_player(bq_player_t *bq_plr, uint8_t run_callback) {
	bq_plr->in_usage = 0;
	bq_plr->looped = 0;
	bq_plr->sound = NULL;
	if (run_callback) caml_callback(bq_plr->callback, Val_unit);
	caml_remove_generational_global_root(&bq_plr->callback);
}

void bqPlayerCallback(SLAndroidSimpleBufferQueueItf bq, void *context) {
	bq_player_t *bq_plr = (bq_player_t*)context;
    SOUND_ASSERT(bq == bq_plr->bqPlayerBufferQueue, "alsound buffer queue player callback buffer queue");

    PRINT_DEBUG("player %d finished", bq_plr->id);

    // for streaming playback, replace this test by logic to find and fill the next buffer
    if (bq_plr->looped) {
        SLresult result = (*bq_plr->bqPlayerBufferQueue)->Enqueue(bq_plr->bqPlayerBufferQueue, bq_plr->sound->buf, bq_plr->sound->len);
        SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound buffer queue player enqueue");
    } else {
    	free_bq_player(bq_plr, 1);
    }
}

bq_player_t *make_bq_player() {
	PRINT_DEBUG("making new player");

	bq_player_t *bq_plr = (bq_player_t*)malloc(sizeof(bq_player_t));
	memset(bq_plr, 0, sizeof(bq_player_t));

    SLDataLocator_AndroidSimpleBufferQueue loc_bufq = {SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 1};
    SLDataFormat_PCM format_pcm = { SL_DATAFORMAT_PCM, 1, SL_SAMPLINGRATE_24, SL_PCMSAMPLEFORMAT_FIXED_8, SL_PCMSAMPLEFORMAT_FIXED_8, SL_SPEAKER_FRONT_CENTER, SL_BYTEORDER_LITTLEENDIAN };
    SLDataSource audioSrc = {&loc_bufq, &format_pcm};

    // configure audio sink
    SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, outputMixObject};
    SLDataSink audioSnk = {&loc_outmix, NULL};

    // create audio player
    const SLInterfaceID plr_ids[2] = {SL_IID_BUFFERQUEUE, SL_IID_VOLUME};
    const SLboolean plr_req[2] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
    SLresult result = (*engineEngine)->CreateAudioPlayer(engineEngine, &bq_plr->bqPlayerObject, &audioSrc, &audioSnk, 2, plr_ids, plr_req);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "buffer queue player create");

    // realize the player
    result = (*bq_plr->bqPlayerObject)->Realize(bq_plr->bqPlayerObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "buffer queue player realize");

    // get the play interface
    result = (*bq_plr->bqPlayerObject)->GetInterface(bq_plr->bqPlayerObject, SL_IID_PLAY, &bq_plr->bqPlayerPlay);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "player interface getting");

    // get the buffer queue interface
    result = (*bq_plr->bqPlayerObject)->GetInterface(bq_plr->bqPlayerObject, SL_IID_BUFFERQUEUE, &bq_plr->bqPlayerBufferQueue);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "queue interface getting");

    // get the volume interface
    result = (*bq_plr->bqPlayerObject)->GetInterface(bq_plr->bqPlayerObject, SL_IID_VOLUME, &bq_plr->bqPlayerVolume);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "volume interface getting");

    result = (*bq_plr->bqPlayerBufferQueue)->RegisterCallback(bq_plr->bqPlayerBufferQueue, bqPlayerCallback, bq_plr);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "buffer queue player registering callback");

    return bq_plr;
}

bq_player_t *get_free_bq_player() {
	PRINT_DEBUG("searching for free player");
	int i = 0;
	bq_player_t *bq_plr;

	for (i = 0; i < bq_players_num; i++) {
		bq_plr = *(bq_players + i);
		if (!bq_plr->in_usage) {
			PRINT_DEBUG("have free player");
			return bq_plr;
		}
	}

	bq_plr = make_bq_player();
	bq_plr->id = bq_players_num;
	bq_players = (bq_player_t**)realloc(bq_players, sizeof(bq_player_t*) * ++bq_players_num);
	*(bq_players + bq_players_num - 1) = bq_plr;

	return bq_plr;
}

value ml_alsoundInit() {
	CAMLparam0();

    SLresult result = slCreateEngine(&engineObject, 0, NULL, 0, NULL, NULL);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "engine create");

    // realize the engine
    result = (*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "engine realize");

    // get the engine interface, which is needed in order to create other objects
    result = (*engineObject)->GetInterface(engineObject, SL_IID_ENGINE, &engineEngine);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "getting SL_IID_ENGINE interface");

    // create output mix, with environmental reverb specified as a non-required interface
    const SLInterfaceID mix_ids[] = {};
    const SLboolean mix_req[] = {};
    result = (*engineEngine)->CreateOutputMix(engineEngine, &outputMixObject, 0, mix_ids, mix_req);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "output mix create");

    // realize the output mix
    result = (*outputMixObject)->Realize(outputMixObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "output mix realizer");

	CAMLreturn(Val_unit);
}

struct WAVHeader{
    char                RIFF[4];        
    unsigned long       ChunkSize;      
    char                WAVE[4];        
    char                fmt[4];         
    unsigned long       Subchunk1Size;
    unsigned short      AudioFormat;    
    unsigned short      NumOfChan;      
    unsigned long       SamplesPerSec;  
    unsigned long       bytesPerSec;  
    unsigned short      blockAlign;     
    unsigned short      bitsPerSample;  
    char                Subchunk2ID[4]; 
    unsigned long       Subchunk2Size;  
};

value ml_alsoundLoad(value vpath) {
	CAMLparam1(vpath);

	resource r;
	SOUND_ASSERT(getResourceFd(String_val(vpath), &r), "cannot load sound");

	alsound_t *alsnd = (alsound_t*)malloc(sizeof(alsound_t));
	alsnd->len = r.length - sizeof(struct WAVHeader);
	alsnd->buf = malloc(alsnd->len);
	
	lseek(r.fd, sizeof(struct WAVHeader), SEEK_CUR);
	read(r.fd, alsnd->buf, alsnd->len);
	close(r.fd);

	CAMLreturn((value)alsnd);
}

value ml_alsoundSetVolume(value player, value vol) {
	CAMLparam2(player, vol);

	bq_player_t *bq_plr = (bq_player_t*)player;
	PRINT_DEBUG("ATTENUATION %d", ATTENUATION(vol));
    SLresult result = (*bq_plr->bqPlayerVolume)->SetVolumeLevel(bq_plr->bqPlayerVolume, ATTENUATION(vol));
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound set volume");

	CAMLreturn(Val_unit);	
}

value ml_alsoundSetLoop(value player, value loop) {
	CAMLparam2(player, loop);

	bq_player_t *bq_plr = (bq_player_t*)player;
	bq_plr->looped = loop == Val_true;
	
	CAMLreturn(Val_unit);
}

value ml_alsoundPlay(value sound, value vol, value loop, value callback) {
	CAMLparam3(sound, vol, loop);

	bq_player_t *bq_plr = get_free_bq_player();
	bq_plr->in_usage = 1;
	bq_plr->looped = loop == Val_true;
	bq_plr->callback = callback;
	caml_register_generational_global_root(&bq_plr->callback);
	ml_alsoundSetVolume((value)bq_plr, vol);

    SLresult result = (*bq_plr->bqPlayerPlay)->SetPlayState(bq_plr->bqPlayerPlay, SL_PLAYSTATE_PLAYING);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound play");

    alsound_t *alsnd = (alsound_t*)sound;
    bq_plr->sound = alsnd;
    result = (*bq_plr->bqPlayerBufferQueue)->Enqueue(bq_plr->bqPlayerBufferQueue, alsnd->buf, alsnd->len);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound enqueue");

	CAMLreturn((value)bq_plr);
}

value ml_alsoundPause(value player) {
	CAMLparam1(player);

	bq_player_t *bq_plr = (bq_player_t*)player;
    SLresult result = (*bq_plr->bqPlayerPlay)->SetPlayState(bq_plr->bqPlayerPlay, SL_PLAYSTATE_PAUSED);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound pause");

	CAMLreturn(Val_unit);
}

value ml_alsoundStop(value player) {
	CAMLparam1(player);

	bq_player_t *bq_plr = (bq_player_t*)player;
    SLresult result = (*bq_plr->bqPlayerPlay)->SetPlayState(bq_plr->bqPlayerPlay, SL_PLAYSTATE_STOPPED);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound stop");
    free_bq_player(bq_plr, 0);

	CAMLreturn(Val_unit);	
}





value ml_avsound_create_player(value vpath) {
	CAMLparam0();
	CAMLreturn(Val_unit);	
}

value ml_avsound_playback(value vmp, value vmethodName) {
	CAMLparam0();
	CAMLreturn(Val_unit);	
}

value ml_avsound_set_loop(value vmp, value loop) {
	CAMLparam0();
	CAMLreturn(Val_unit);
}

value ml_avsound_set_volume(value vmp, value vol) {
	CAMLparam0();
	CAMLreturn(Val_unit);	
}

value ml_avsound_is_playing(value vmp) {
	CAMLparam0();
	CAMLreturn(Val_unit);	
}

value ml_avsound_play(value vmp, value cb) {
	CAMLparam0();
	CAMLreturn(Val_unit);	
}

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
