#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>

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







typedef struct {
	SLObjectItf fdPlayerObject;
	SLPlayItf fdPlayerPlay;
	SLSeekItf fdPlayerSeek;
	SLVolumeItf fdPlayerVolume;
	value callback;
} fd_player_t;

void fdPlayerCallback(SLPlayItf caller, void *context, SLuint32 event) {
	PRINT_DEBUG("fdPlayerCallback CALL");

	fd_player_t *fd_plr = (fd_player_t*)context;
    SOUND_ASSERT(caller == fd_plr->fdPlayerPlay, "avsound strange caller");
    SOUND_ASSERT(event == SL_PLAYEVENT_HEADATEND, "avsound unexpected event");

    caml_callback(fd_plr->callback, Val_unit);
    caml_remove_generational_global_root(&fd_plr->callback);
}

value ml_avsound_create_player(value vpath) {
	CAMLparam1(vpath);

	fd_player_t *fd_plr = (fd_player_t*)malloc(sizeof(fd_player_t));
	memset(fd_plr, 0, sizeof(fd_player_t));

	resource r;
	SOUND_ASSERT(getResourceFd(String_val(vpath), &r), "cannot load sound");

    SLDataLocator_AndroidFD loc_fd = {SL_DATALOCATOR_ANDROIDFD, r.fd, r.offset, r.length};
    SLDataFormat_MIME format_mime = {SL_DATAFORMAT_MIME, NULL, SL_CONTAINERTYPE_UNSPECIFIED};
    SLDataSource audioSrc = {&loc_fd, &format_mime};

    // configure audio sink
    SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, outputMixObject};
    SLDataSink audioSnk = {&loc_outmix, NULL};

    // create audio player
    const SLInterfaceID ids[2] = {SL_IID_SEEK, SL_IID_VOLUME};
	const SLboolean req[2] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
	SLresult result = (*engineEngine)->CreateAudioPlayer(engineEngine, &fd_plr->fdPlayerObject, &audioSrc, &audioSnk, 2, ids, req);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player");

    // realize the player
    result = (*fd_plr->fdPlayerObject)->Realize(fd_plr->fdPlayerObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player realize");

    // get the play interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_PLAY, &fd_plr->fdPlayerPlay);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get play interface");

    // get the seek interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_SEEK, &fd_plr->fdPlayerSeek);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get seek interface");

    // get the volume interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_VOLUME, &fd_plr->fdPlayerVolume);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get volume interface");

	CAMLreturn((value)fd_plr);
}

value ml_avsound_set_loop(value player, value loop) {
	CAMLparam2(player, loop);

	fd_player_t *fd_plr = (fd_player_t*)player;
    SLresult result = (*fd_plr->fdPlayerSeek)->SetLoop(fd_plr->fdPlayerSeek, loop = Val_true ? SL_BOOLEAN_TRUE : SL_BOOLEAN_FALSE, 0, SL_TIME_UNKNOWN);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound set loop");

	CAMLreturn(Val_unit);
}

value ml_avsound_set_volume(value player, value vol) {
	CAMLparam2(player, vol);

	fd_player_t *fd_plr = (fd_player_t*)player;
    SLresult result = (*fd_plr->fdPlayerVolume)->SetVolumeLevel(fd_plr->fdPlayerVolume, ATTENUATION(vol));
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound set volume");

	CAMLreturn(Val_unit);
}

value ml_avsound_play(value player, value callback) {
	PRINT_DEBUG("ml_avsound_play call");

	CAMLparam2(player, callback);

	fd_player_t *fd_plr = (fd_player_t*)player;
	fd_plr->callback = callback;
	caml_register_generational_global_root(&fd_plr->callback);

    SLresult result = (*fd_plr->fdPlayerPlay)->SetCallbackEventsMask(fd_plr->fdPlayerPlay, SL_PLAYEVENT_HEADATEND);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound set callback mask");

    result = (*fd_plr->fdPlayerPlay)->RegisterCallback(fd_plr->fdPlayerPlay, fdPlayerCallback, fd_plr);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound register callback");

    result = (*fd_plr->fdPlayerPlay)->SetPlayState(fd_plr->fdPlayerPlay, SL_PLAYSTATE_PLAYING);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound play");    

	CAMLreturn(Val_unit);
}

value ml_avsound_stop(value player) {
	CAMLparam1(player);

	fd_player_t *fd_plr = (fd_player_t*)player;
    SLresult result = (*fd_plr->fdPlayerPlay)->SetPlayState(fd_plr->fdPlayerPlay, SL_PLAYSTATE_STOPPED);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound stop");

	CAMLreturn(Val_unit);	
}

value ml_avsound_pause(value player) {
	CAMLparam1(player);

	fd_player_t *fd_plr = (fd_player_t*)player;
    SLresult result = (*fd_plr->fdPlayerPlay)->SetPlayState(fd_plr->fdPlayerPlay, SL_PLAYSTATE_PAUSED);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound pause");

	CAMLreturn(Val_unit);	
}

value ml_avsound_release(value player) {
	CAMLparam1(player);

	fd_player_t *fd_plr = (fd_player_t*)player;
	(*fd_plr->fdPlayerObject)->Destroy(fd_plr->fdPlayerObject);
	free(fd_plr);

	CAMLreturn(Val_unit);
}
