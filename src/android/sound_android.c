#include "lightning_android.h"
#include "engine_android.h"
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <unistd.h>

static SLObjectItf engineObject = NULL;
static SLEngineItf engineEngine;
static SLObjectItf outputMixObject = NULL;

typedef struct {
    SLuint32 sample_rate;
    SLuint16 bits_per_sample;
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


// calling this function from main ui thread cause from any other thread it blocks forever. reasons unknown
void bq_player_free(void *d) {
    PRINT_DEBUG("bq_player_free %d", gettid());
    bq_player_t *plr = (bq_player_t*)d;
    (*plr->bqPlayerObject)->Destroy(plr->bqPlayerObject);
    free(plr);
    PRINT_DEBUG("bq_player_free done");
}

typedef struct {
    bq_player_t *plr;
    uint8_t run_callback;
} bq_player_callback_t;

void bq_player_callback(void *d) {
    PRINT_DEBUG("bq_player_callback %d", gettid());

    bq_player_callback_t *data = (bq_player_callback_t*)d;

    caml_remove_generational_global_root(&data->plr->callback);
    if (data->run_callback) {
        caml_callback(data->plr->callback, Val_unit);
    }

    RUN_ON_UI_THREAD(&bq_player_free, data->plr);
    free(data);
}

void run_bq_player_callback(bq_player_t *bq_plr, uint8_t run_callback) {
    PRINT_DEBUG("run_bq_player_callback %d", gettid());

    bq_player_callback_t *data = (bq_player_callback_t*)malloc(sizeof(bq_player_callback_t));
    data->plr = bq_plr;
    data->run_callback = run_callback;
    RUN_ON_ML_THREAD(&bq_player_callback, data);
}

void bqPlayerCallback(SLAndroidSimpleBufferQueueItf bq, void *context) {
    bq_player_t *bq_plr = (bq_player_t*)context;
    SOUND_ASSERT(bq == bq_plr->bqPlayerBufferQueue, "alsound buffer queue player callback buffer queue");

    // for streaming playback, replace this test by logic to find and fill the next buffer
    if (bq_plr->looped) {
        SLresult result = (*bq_plr->bqPlayerBufferQueue)->Enqueue(bq_plr->bqPlayerBufferQueue, bq_plr->sound->buf, bq_plr->sound->len);
        SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound buffer queue player enqueue");
    } else {
        run_bq_player_callback(bq_plr, 1);
    }
}

bq_player_t *make_bq_player(SLuint32 sample_rate, SLuint16 bits_per_sample) {
    PRINT_DEBUG("make_bq_player %d", gettid());

    bq_player_t *bq_plr = (bq_player_t*)malloc(sizeof(bq_player_t));
		bq_plr->callback = 0;
    memset(bq_plr, 0, sizeof(bq_player_t));

    PRINT_DEBUG("bits_per_sample %x %x", bits_per_sample, SL_PCMSAMPLEFORMAT_FIXED_8);

    SLDataLocator_AndroidSimpleBufferQueue loc_bufq = {SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 1};
    SLDataFormat_PCM format_pcm = { SL_DATAFORMAT_PCM, 1, sample_rate, bits_per_sample, bits_per_sample, SL_SPEAKER_FRONT_CENTER, SL_BYTEORDER_LITTLEENDIAN };
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
    const SLInterfaceID mix_ids[] = {SL_IID_ENVIRONMENTALREVERB};
    const SLboolean mix_req[] = {SL_BOOLEAN_FALSE};
    result = (*engineEngine)->CreateOutputMix(engineEngine, &outputMixObject, 1, mix_ids, mix_req);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "output mix create");

    SLEnvironmentalReverbItf outputMixEnvironmentalReverb;
    SLEnvironmentalReverbSettings reverbSettings = SL_I3DL2_ENVIRONMENT_PRESET_STONECORRIDOR;
    if (SL_RESULT_SUCCESS == (*outputMixObject)->GetInterface(outputMixObject, SL_IID_ENVIRONMENTALREVERB, &outputMixEnvironmentalReverb)) {
        (*outputMixEnvironmentalReverb)->SetEnvironmentalReverbProperties(outputMixEnvironmentalReverb, &reverbSettings);
    }

    // realize the output mix
    result = (*outputMixObject)->Realize(outputMixObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "output mix realizer");

    CAMLreturn(Val_unit);
}

#define MAKEFOURCC(ch0, ch1, ch2, ch3) \
    ((uint32_t)((int8_t)(ch0)) | ((uint32_t)((int8_t)(ch1)) << 8) | \
    ((uint32_t)((int8_t)(ch2)) << 16) | ((uint32_t)((int8_t)(ch3)) << 24 ))

#define CAF_FILETYPE MAKEFOURCC('c','a','f','f')
#define DESC_CHUNK_TYPE MAKEFOURCC('d','e','s','c')
#define DATA_CHUNK_TYPE MAKEFOURCC('d','a','t','a')
#define LPCM_FORMAT_ID MAKEFOURCC('l','p','c','m')

typedef struct {
    uint32_t file_type;
    uint16_t file_ver;
    uint16_t file_flags;
} caf_header_t;

typedef struct {
    uint32_t chunk_type;
    int64_t chunk_size;
} __attribute__((packed)) caf_chunk_header_t;

typedef struct {
    int64_t sample_rate;
    uint32_t format_id;
    uint32_t format_flags;
    uint32_t bytes_per_packet;
    uint32_t frames_per_packet;
    uint32_t channels_per_frame;
    uint32_t bits_per_channel;
} __attribute__((packed)) caf_audio_desc_chunk_t;

#include <endian.h>

value ml_alsoundLoad(value vpath) {
    CAMLparam1(vpath);

    resource r;
    SOUND_ASSERT(getResourceFd(String_val(vpath), &r), "cannot load sound");

    alsound_t *alsnd = (alsound_t*)malloc(sizeof(alsound_t));

    caf_header_t caf_hdr;
    caf_chunk_header_t chunk_hdr;
    caf_audio_desc_chunk_t desc_chunk;

    int64_t total_bytes_read = 0;
    ssize_t bytes_read = 0;

    SOUND_ASSERT(sizeof(caf_header_t) == (bytes_read = read(r.fd, &caf_hdr, sizeof(caf_header_t))), "cannot read caf header");
    total_bytes_read += bytes_read;
    SOUND_ASSERT(caf_hdr.file_type == CAF_FILETYPE, "given file is not caf");

    int64_t chunk_size;
    uint8_t desc_read = 0;
    uint8_t data_read = 0;

    do {
        //using swap32 swap64 cause caf header ints are big endian ints, but android is little endian

        SOUND_ASSERT(sizeof(caf_chunk_header_t) == (bytes_read = read(r.fd, &chunk_hdr, sizeof(caf_chunk_header_t))), "cannot caf chunk header");
        total_bytes_read += bytes_read;
        chunk_size = swap64(chunk_hdr.chunk_size);

        switch (chunk_hdr.chunk_type) {
            case DESC_CHUNK_TYPE:
                SOUND_ASSERT(sizeof(caf_audio_desc_chunk_t) == read(r.fd, &desc_chunk, sizeof(caf_audio_desc_chunk_t)), "cannot read audio description chunk");
                SOUND_ASSERT(desc_chunk.format_id == LPCM_FORMAT_ID, "'lpcm' format id expected");
                SOUND_ASSERT(swap32(desc_chunk.format_flags) & (1 << 1), "pcm data should be in little endian");
                desc_read = 1;

                int64_t isample_rate = swap64(desc_chunk.sample_rate);
                double dsample_rate;
                memcpy(&dsample_rate, &isample_rate, sizeof(double));

                alsnd->sample_rate = (SLuint32)(dsample_rate * 1000.);
                alsnd->bits_per_sample = (SLuint16)swap32(desc_chunk.bits_per_channel);

                PRINT_DEBUG("alsnd->sample_rate %d, alsnd->bits_per_sample %d", alsnd->sample_rate, alsnd->bits_per_sample);

                break;

            case DATA_CHUNK_TYPE:
                lseek(r.fd, 4, SEEK_CUR); //caf audio aata chunk contains 32-bit edit_count field followed by audio data, skiping edit_count
                alsnd->len = chunk_size - 4;
                alsnd->buf = malloc(alsnd->len);
                SOUND_ASSERT(alsnd->len == read(r.fd, alsnd->buf, alsnd->len), "cannot read audio data chunk");
                data_read = 1;

                break;

            default:
                lseek(r.fd, chunk_size, SEEK_CUR);
        }

        total_bytes_read += chunk_size;
    } while (total_bytes_read < r.length);

    SOUND_ASSERT(desc_read, "no audio description chunk present");
    SOUND_ASSERT(data_read, "no audio data chunk present");

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
    CAMLparam4(sound, vol, loop, callback);

    alsound_t *alsnd = (alsound_t*)sound;

    bq_player_t *bq_plr = make_bq_player(alsnd->sample_rate, alsnd->bits_per_sample);
    bq_plr->in_usage = 1;
    bq_plr->looped = loop == Val_true;

		if (!bq_plr->callback) {
			bq_plr->callback = callback;
			caml_register_generational_global_root(&bq_plr->callback);
		} else {
			caml_modify_generational_global_root(&bq_plr->callback, callback);
		}

    ml_alsoundSetVolume((value)bq_plr, vol);

    SLresult result = (*bq_plr->bqPlayerPlay)->SetPlayState(bq_plr->bqPlayerPlay, SL_PLAYSTATE_PLAYING);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "alsound play");
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
    run_bq_player_callback(bq_plr, 0);

    CAMLreturn(Val_unit);
}

typedef struct fd_player {
    SLObjectItf fdPlayerObject;
    SLPlayItf fdPlayerPlay;
    SLSeekItf fdPlayerSeek;
    SLVolumeItf fdPlayerVolume;
    value callback;
    struct fd_player* next;
    struct fd_player* prev;
    uint8_t resume_onforeground;
} fd_player_t;

fd_player_t *head = NULL;

void run_avplayer_callback(void *data) {
    PRINT_DEBUG("run_avplayer_callback %d", gettid());

    fd_player_t *fd_plr = (fd_player_t*)data;
    caml_callback(fd_plr->callback, Val_unit);
}

void fdPlayerCallback(SLPlayItf caller, void *context, SLuint32 event) {
    PRINT_DEBUG("fdPlayerCallback CALL %d", gettid());

    fd_player_t *fd_plr = (fd_player_t*)context;
    SOUND_ASSERT(caller == fd_plr->fdPlayerPlay, "avsound strange caller");
    SOUND_ASSERT(event == SL_PLAYEVENT_HEADATEND, "avsound unexpected event");

    SLresult result = (*fd_plr->fdPlayerPlay)->SetPlayState(fd_plr->fdPlayerPlay, SL_PLAYSTATE_STOPPED);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound stop");

    RUN_ON_ML_THREAD(&run_avplayer_callback, context);
}

value ml_avsound_create_player(value vpath) {
    CAMLparam1(vpath);

    fd_player_t *fd_plr = (fd_player_t*)malloc(sizeof(fd_player_t));
	fd_plr->callback = 0;
    memset(fd_plr, 0, sizeof(fd_player_t));

    if (!head) {
        head = fd_plr;
        head->next = head;
        head->prev = head;
    } else {
        fd_plr->prev = head->prev;
        fd_plr->next = head;
        head->prev->next = fd_plr;
        head->prev = fd_plr;
    }

    resource r;
    SOUND_ASSERT(getResourceFd(String_val(vpath), &r), "cannot load sound");


		PRINT_DEBUG("CHPNT1");

    SLDataLocator_AndroidFD loc_fd = {SL_DATALOCATOR_ANDROIDFD, r.fd, r.offset, r.length};
    SLDataFormat_MIME format_mime = {SL_DATAFORMAT_MIME, NULL, SL_CONTAINERTYPE_UNSPECIFIED};
    SLDataSource audioSrc = {&loc_fd, &format_mime};
		PRINT_DEBUG("CHPNT1");

    // configure audio sink
    SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, outputMixObject};
    SLDataSink audioSnk = {&loc_outmix, NULL};

		PRINT_DEBUG("CHPNT1");
    // create audio player
    const SLInterfaceID ids[2] = {SL_IID_SEEK, SL_IID_VOLUME};
    const SLboolean req[2] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
    SLresult result = (*engineEngine)->CreateAudioPlayer(engineEngine, &fd_plr->fdPlayerObject, &audioSrc, &audioSnk, 2, ids, req);
		PRINT_DEBUG("CHPNT1");
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player");
		PRINT_DEBUG("CHPNT1");

    // realize the player
    result = (*fd_plr->fdPlayerObject)->Realize(fd_plr->fdPlayerObject, SL_BOOLEAN_FALSE);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player realize");

    // get the play interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_PLAY, &fd_plr->fdPlayerPlay);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get play interface");
		PRINT_DEBUG("CHPNT1");

    // get the seek interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_SEEK, &fd_plr->fdPlayerSeek);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get seek interface");

    // get the volume interface
    result = (*fd_plr->fdPlayerObject)->GetInterface(fd_plr->fdPlayerObject, SL_IID_VOLUME, &fd_plr->fdPlayerVolume);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound create player get volume interface");

    result = (*fd_plr->fdPlayerPlay)->SetCallbackEventsMask(fd_plr->fdPlayerPlay, SL_PLAYEVENT_HEADATEND);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound set callback mask");

    result = (*fd_plr->fdPlayerPlay)->RegisterCallback(fd_plr->fdPlayerPlay, fdPlayerCallback, fd_plr);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound register callback");
		PRINT_DEBUG("CHPNT1");

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
    PRINT_DEBUG("ml_avsound_play call %d", gettid());

    CAMLparam2(player, callback);

    fd_player_t *fd_plr = (fd_player_t*)player;

		if (!fd_plr->callback) {
			fd_plr->callback = callback;
			caml_register_generational_global_root(&fd_plr->callback);
		} else {
			caml_modify_generational_global_root(&fd_plr->callback, callback);
		}

    SLresult result = (*fd_plr->fdPlayerPlay)->SetPlayState(fd_plr->fdPlayerPlay, SL_PLAYSTATE_PLAYING);
    SOUND_ASSERT(SL_RESULT_SUCCESS == result, "avsound play");

    CAMLreturn(Val_unit);
}

value ml_avsound_stop(value player) {
    PRINT_DEBUG("ml_avsound_stop");

    CAMLparam1(player);

    fd_player_t *fd_plr = (fd_player_t*)player;
		if (fd_plr->callback) {
			caml_remove_generational_global_root(&fd_plr->callback);
			fd_plr->callback = 0;
		}
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
    PRINT_DEBUG("ml_avsound_release");

    CAMLparam1(player);

    fd_player_t *fd_plr = (fd_player_t*)player;
		caml_remove_generational_global_root(&fd_plr->callback);
    (*fd_plr->fdPlayerObject)->Destroy(fd_plr->fdPlayerObject);

    if (fd_plr->next == fd_plr) {
        head = NULL;
    } else {
        fd_plr->prev->next = fd_plr->next;
        fd_plr->next->prev = fd_plr->prev;

        if (fd_plr == head) {
            head = fd_plr->next;
        }
    }

    free(fd_plr);

    CAMLreturn(Val_unit);
}

void sound_android_onbackground() {
    if (!head) return;

    fd_player_t *plr = head;
    SLuint32 state;
    SLresult res;

    do {
        res = (*plr->fdPlayerPlay)->GetPlayState(plr->fdPlayerPlay, &state);
        SOUND_ASSERT(SL_RESULT_SUCCESS == res, "sound_android_onbackground");

        if (state == SL_PLAYSTATE_PLAYING) {
            plr->resume_onforeground = 1;

            res = (*plr->fdPlayerPlay)->SetPlayState(plr->fdPlayerPlay, SL_PLAYSTATE_PAUSED);
            SOUND_ASSERT(SL_RESULT_SUCCESS == res, "sound_android_onbackground");
        } else {
            plr->resume_onforeground = 0;
        }

        plr = plr->next;
    } while (plr != head);
}

void sound_android_onforeground() {
    if (!head) return;

    fd_player_t *plr = head;
    SLresult res;

    do {
        if (plr->resume_onforeground) {
            res = (*plr->fdPlayerPlay)->SetPlayState(plr->fdPlayerPlay, SL_PLAYSTATE_PLAYING);
            SOUND_ASSERT(SL_RESULT_SUCCESS == res, "sound_android_onforeground");
        }

        plr = plr->next;
    } while (plr != head);
}
