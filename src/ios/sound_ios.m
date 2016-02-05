
#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

#import "light_common.h"
#import "common_ios.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/callback.h>
#import <caml/fail.h>
#include <caml/custom.h>
#import <caml/alloc.h>
#import <caml/threads.h>
#import <errno.h>

static unsigned int total_sound_mem = 0;

extern uintnat caml_dependent_size;
#ifdef DEBUG_MEM
#define LOGMEM(op,size) DEBUGMSG("SOUND MEMORY <%s> %u -> %u:%u",op,size,total_sound_mem,caml_dependent_size)
#else
#define LOGMEM(op,size)
#endif


#define checkOpenALError(fmt,args...) { \
	ALenum errorCode = alGetError(); \
	if (errorCode != AL_NO_ERROR) { \
		char buf[256]; \
		int bw = sprintf(buf,"(%s:%d) al error [%x]. ",__FILE__,__LINE__,errorCode); \
		sprintf(buf + bw,fmt,## args); \
		caml_raise_with_string(*caml_named_value("Audio_error"),buf); \
	}; \
}


static void raise_error(char* message, char* fname, uint code) {
	char buf[256];
	if (fname)
		sprintf(buf,"%s '%s' [%x]", message,fname,code);
	else
		sprintf(buf,"%s [%x]", message,code);
	caml_raise_with_string(*caml_named_value("Audio_error"),buf);
}

void interruptionCallback (void *inUserData, UInt32 interruptionState) {
	/*
    if (interruptionState == kAudioSessionBeginInterruption)
        [SPAudioEngine beginInterruption];
    else if (interruptionState == kAudioSessionEndInterruption)
        [SPAudioEngine endInterruption];
				*/
}

// SESSION
static ALCdevice  *device  = NULL;
static ALCcontext *context = NULL;

/* DEPRECATED
 *
value ml_sound_init(value mlSessionCategory,value unit) {
	if (device) return Val_unit;
	OSStatus result;
	result = AudioSessionInitialize(NULL, NULL, interruptionCallback, NULL);
	if (result != kAudioSessionNoError) raise_error("Could not initialize audio",NULL,result);
  UInt32 sessionCategory;
	switch (Int_val(mlSessionCategory)) {
		case 0: sessionCategory = 'ambi'; break;
		case 1: sessionCategory = 'solo'; break;
		case 2: sessionCategory = 'medi'; break;
		case 3: sessionCategory = 'reca'; break;
		case 4: sessionCategory = 'plar'; break;
		case 5: sessionCategory = 'proc'; break;
	};
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	result = AudioSessionSetActive(YES);
	if (result != kAudioSessionNoError) raise_error("Could not activate audio session",NULL,result);

	// Init OpenAL
	alGetError(); // reset any errors

	device = alcOpenDevice(NULL);
	if (!device) raise_error("Could not open default OpenAL device",NULL,0);

	context = alcCreateContext(device, 0);
	if (!context) raise_error("Could not create OpenAL context for default device",NULL,0);

	BOOL success = alcMakeContextCurrent(context);
	if (!success) raise_error("Could not set current OpenAL context",NULL,0);
	return Val_unit;
}
*/

value ml_sound_init(value mlSessionCategory,value unit) {
	if (device) return Val_unit;
	/*
	OSStatus result;
	result = AudioSessionInitialize(NULL, NULL, interruptionCallback, NULL);
	if (result != kAudioSessionNoError) raise_error("Could not initialize audio",NULL,result);
  UInt32 sessionCategory;
	switch (Int_val(mlSessionCategory)) {
		case 0: sessionCategory = 'ambi'; break;
		case 1: sessionCategory = 'solo'; break;
		case 2: sessionCategory = 'medi'; break;
		case 3: sessionCategory = 'reca'; break;
		case 4: sessionCategory = 'plar'; break;
		case 5: sessionCategory = 'proc'; break;
	};
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	result = AudioSessionSetActive(YES);
	if (result != kAudioSessionNoError) raise_error("Could not activate audio session",NULL,result);
	*/

	NSError* error;

	// Init OpenAL
	alGetError(); // reset any errors

	device = alcOpenDevice(NULL);
	if (!device) raise_error("Could not open default OpenAL device",NULL,0);

	context = alcCreateContext(device, 0);
	if (!context) raise_error("Could not create OpenAL context for default device",NULL,0);

	BOOL success = alcMakeContextCurrent(context);
	if (!success) raise_error("Could not set current OpenAL context",NULL,0);

	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	if (!error) raise_error("Could not activate audio session", NULL, (uint)([error code]));

	return Val_unit;
}

// ALSOUND

value ml_al_setMasterVolume(value mlVolume) {
	alListenerf(AL_GAIN, Double_val(mlVolume));
	return Val_unit;
}

struct albuffer {
	uint bufferID;
	size_t soundSize;
};

#define ALBUFFER(v) ((struct albuffer*)Data_custom_val(v))
static void albuffer_finalize(value mlAlBuffer) {
	struct albuffer *b = ALBUFFER(mlAlBuffer);
	PRINT_DEBUG("albuffer finalize: %d",b->bufferID);
	//checkOpenALError("finalize albuffer: %d",bufferID);
	alDeleteBuffers(1,&(b->bufferID));
	caml_free_dependent_memory(b->soundSize);
	LOGMEM("finalize",b->soundSize);
}

struct custom_operations albuffer_ops = {
  "pointer to alsound",
  albuffer_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


/*NSString* pathForResource(NSString *path) {
	NSString *fullPath = NULL;
	if ([path isAbsolutePath]) {
			fullPath = path;
	} else {
		fullPath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
	}
	if (!fullPath)
	{
		const char *fname = [path cStringUsingEncoding:NSASCIIStringEncoding];
		caml_raise_with_string(*caml_named_value("File_not_exists"), fname);
	}
	return fullPath;
}*/

OSStatus MyAudioFile_ReadProc(void* inClientData, SInt64 inPosition, UInt32 requestCount, void* buffer, UInt32* actualCount) {
	resource* res = (resource*)inClientData;

	int seek_res = lseek(res->fd, res->offset + inPosition, SEEK_SET);

	if (seek_res < 0) {
		if (errno == EBADF) return kAudioFileNotOpenError;
		if (errno == EOVERFLOW) return kAudioFilePositionError;

		return kAudioFileUnspecifiedError;
	}

	*actualCount = read(res->fd, buffer, requestCount);
	if (*actualCount < 0) return kAudioFileUnspecifiedError;

	return noErr;
}

OSStatus MyAudioFile_WriteProc (void *inClientData, SInt64 inPosition, UInt32 requestCount, void *buffer, UInt32 *actualCount) {
	return kAudioFileOperationNotSupportedError;
}

SInt64 MyAudioFile_GetSizeProc (void *inClientData) {
	return ((resource*)inClientData)->length;
}

SInt64 MyAudioFile_SetSizeProc (void *inClientData) {
	return -1;
}

CAMLprim value ml_albuffer_create(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal2(mlBuffer,mlres);

	char* c_path = String_val(mlpath);
	NSString *path = [NSString stringWithCString:c_path encoding:NSASCIIStringEncoding];
	// NSString *fullPath = pathForResource(path);

	AudioFileID fileID = 0;
	void *soundBuffer = NULL;
	int   soundSize = 0;
	int   soundChannels = 0;
	int   soundFrequency = 0;
	double soundDuration = 0.0;

	OSStatus result = noErr;

	if ([path isAbsolutePath]) {
		result = AudioFileOpenURL((CFURLRef) [NSURL fileURLWithPath:path], kAudioFileReadPermission, 0, &fileID);
	} else {
		resource* res = (resource*)malloc(sizeof(resource));
		if (!getResourceFd(c_path, res)) {
			free(res);
			raise_error("could not obtain resource fd", String_val(mlpath), kAudioFileInvalidFileError);
		}

		result = AudioFileOpenWithCallbacks((void*)res, MyAudioFile_ReadProc, MyAudioFile_WriteProc, MyAudioFile_GetSizeProc, MyAudioFile_SetSizeProc, 0, &fileID);
	}

	if (result != noErr) raise_error("could not read audio file",String_val(mlpath),result);

	AudioStreamBasicDescription fileFormat;

	UInt32 propertySize = sizeof(fileFormat);
	result = AudioFileGetProperty(fileID, kAudioFilePropertyDataFormat, &propertySize, &fileFormat);
	if (result != noErr) {
		AudioFileClose(fileID);
		raise_error("could not read file format info",String_val(mlpath),result);
	};

	if (fileFormat.mFormatID != kAudioFormatLinearPCM) {
		AudioFileClose(fileID);
		raise_error("sound file not linear PCM",String_val(mlpath),noErr);
	};

	if (fileFormat.mChannelsPerFrame > 2) {
		AudioFileClose(fileID);
		raise_error("more than two channels in sound file",String_val(mlpath),noErr);
	}

	if (!TestAudioFormatNativeEndian(fileFormat)) {
		AudioFileClose(fileID);
		raise_error("sounds must be little-endian",String_val(mlpath),noErr);
	}

	propertySize = sizeof(soundDuration);
	result = AudioFileGetProperty(fileID, kAudioFilePropertyEstimatedDuration, &propertySize, &soundDuration);
	if (result != noErr) {
		AudioFileClose(fileID);
		raise_error("could not read sound duration",String_val(mlpath),result);
	};


	if (!(fileFormat.mBitsPerChannel == 8 || fileFormat.mBitsPerChannel == 16)) {
		AudioFileClose(fileID);
		raise_error("only files with 8 or 16 bits per channel supported",String_val(mlpath),noErr);
	}

	UInt64 fileSize = 0;
	propertySize = sizeof(fileSize);
	result = AudioFileGetProperty(fileID, kAudioFilePropertyAudioDataByteCount, &propertySize, &fileSize);
	if (result != noErr) {
		AudioFileClose(fileID);
		raise_error("could not read sound file size",String_val(mlpath),result);
	}

	UInt32 dataSize = (UInt32)fileSize;
	soundBuffer = caml_stat_alloc(dataSize);

	result = AudioFileReadBytes(fileID, false, 0, &dataSize, soundBuffer);
	if (result != noErr) {
		AudioFileClose(fileID);
		caml_stat_free(soundBuffer);
		raise_error("could not read sound data",String_val(mlpath),result);
	}
	soundSize = (int) dataSize;
	soundChannels = fileFormat.mChannelsPerFrame;
	soundFrequency = fileFormat.mSampleRate;
	AudioFileClose(fileID);

	ALCcontext *const currentContext = alcGetCurrentContext();
	if (!currentContext) {
		caml_stat_free(soundBuffer);
		raise_error("Could not get current OpenAL context",String_val(mlpath),noErr);
	}

	ALenum errorCode;

	uint bufferID;
	alGenBuffers(1, &bufferID);
	errorCode = alGetError();
	if (errorCode != AL_NO_ERROR) {
		caml_stat_free(soundBuffer);
		raise_error("Could not allocate OpenAL buffer",String_val(mlpath),errorCode);
	}

	int format = (soundChannels > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;

	alBufferData(bufferID, format, soundBuffer, soundSize, soundFrequency);
	caml_stat_free(soundBuffer);
	errorCode = alGetError();
	if (errorCode != AL_NO_ERROR) raise_error("Could not fill OpenAL buffer",String_val(mlpath),errorCode);

	caml_alloc_dependent_memory(soundSize);
	total_sound_mem += soundSize;
	LOGMEM("alloc",soundSize);

	//mlBuffer = caml_alloc_custom(&albuffer_ops,sizeof(struct albuffer),soundSize,MAX_GC_MEM);
	mlBuffer = caml_alloc_custom(&albuffer_ops,sizeof(struct albuffer),0,1);
	ALBUFFER(mlBuffer)->bufferID = bufferID;
	ALBUFFER(mlBuffer)->soundSize = soundSize;
	mlres = caml_alloc_tuple(2);
	Store_field(mlres,0,mlBuffer);
	Store_field(mlres,1,caml_copy_double(soundDuration));
	PRINT_DEBUG("CREATED new albuffer: %d - %f",bufferID,soundDuration);
	CAMLreturn(mlres);
}


/*
#define ALSOURCEID(v) ((uint*)Data_custom_val(v))
static void alsource_finalize(value mlAlSourceID) {
	uint sourceID = *ALSOURCEID(mlAlSourceID);
	PRINT_DEBUG("alsource finalize: %d",sourceID);
	alSourceStop(sourceID);
	alSourcei(sourceID, AL_BUFFER, 0);
	alDeleteSources(1, &sourceID);
	checkOpenALError("finalize alsource: %d",sourceID);
}

struct custom_operations alsource_ops = {
  "pointer to alsource",
  alsource_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};
*/

CAMLprim value ml_alsource_create(value mlAlBuffer) {
	CAMLparam1(mlAlBuffer);
	CAMLlocal1(mlAlSourceID);
	uint sourceID;
	alGenSources(1, &sourceID);
	uint bufferID = ALBUFFER(mlAlBuffer)->bufferID;
	alSourcei(sourceID, AL_BUFFER, bufferID);
	PRINT_DEBUG("created alsource: %d for buffer %d",sourceID,bufferID);
	//checkOpenALError("create alsource: %d - %d",bufferID,sourceID);
	//mlAlSourceID = caml_alloc_custom(&alsource_ops,sizeof(uint),1,0);
	//*ALSOURCEID(mlAlSourceID) = sourceID;
	mlAlSourceID = caml_copy_int32(sourceID);
	CAMLreturn(mlAlSourceID);
}

value ml_alsource_play(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourcePlay(sourceID);
	PRINT_DEBUG("play source: %d",sourceID);
	// remove after debug
	//checkOpenALError("play: %d",sourceID);
	return Val_unit;
}

value ml_alsource_pause(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourcePause(sourceID);
	PRINT_DEBUG("pause alsource: %d",sourceID);
	// remove after debug
	//checkOpenALError("pause: %d",sourceID);
	return Val_unit;
}

value ml_alsource_stop(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourceStop(sourceID);
	PRINT_DEBUG("stop alsource: %d",sourceID);
	// remove after debug
	//checkOpenALError("play: %d",sourceID);
	return Val_unit;
}

value ml_alsource_setLoop(value mlAlSourceID,value loop) {
	//alSourcei(*ALSOURCEID(mlAlSourceID), AL_LOOPING, Int_val(loop));
	alSourcei(Int32_val(mlAlSourceID), AL_LOOPING, Int_val(loop));
	return Val_unit;
}

value ml_alsource_state(value mlAlSourceID) {
	ALint state;
	//alGetSourcei(*ALSOURCEID(mlAlSourceID), AL_SOURCE_STATE, &state);
	alGetSourcei(Int32_val(mlAlSourceID), AL_SOURCE_STATE, &state);
	int res = 0;
	switch (state) {
		case AL_PLAYING: res = 1; break;
		case AL_PAUSED: res = 2; break;
		case AL_STOPPED: res = 3; break;
		case AL_INITIAL: res = 0; break;
		default: raise_error("unknown alsource state",0,state);
	};
	return Val_int(res);
}
/*
*/

void ml_alsource_setVolume(value mlAlSourceID,value mlVolume) {
	//alSourcef(*ALSOURCEID(mlAlSourceID), AL_GAIN, Double_val(mlVolume)); // set volume
	alSourcef(Int32_val(mlAlSourceID), AL_GAIN, Double_val(mlVolume)); // set volume
}

CAMLprim value ml_alsource_getVolume(value mlAlSourceID) {
	ALfloat volume;
	//alGetSourcef(*ALSOURCEID(mlAlSourceID),AL_GAIN,&volume);
	alGetSourcef(Int32_val(mlAlSourceID),AL_GAIN,&volume);
	return caml_copy_double(volume);
}


value ml_alsource_delete(value mlAlSourceID) {
	uint sourceID = Int32_val(mlAlSourceID);
	alSourceStop(sourceID);
	alSourcei(sourceID, AL_BUFFER, 0);
	alDeleteSources(1, &sourceID);
	return Val_unit;
}



@interface AVSoundPlayerController : NSObject <AVAudioPlayerDelegate> {
  AVAudioPlayer * _player;
  value _sound_stopped_handler;
}
-(id)initWithFilename: (NSString *)fname;
@end


@implementation AVSoundPlayerController

/* * */
-(id)initWithFilename: (NSString *)fname {
	self = [super init];
	if (self) {

		if ([fname isAbsolutePath]) {
			NSURL * sndurl = [[NSBundle mainBundle] URLForResource: fname withExtension: nil];
			if (sndurl == nil) {
				[self release];
				caml_failwith("can't find sound");
			}

			NSError *error = nil;
			_player  = [[AVAudioPlayer alloc] initWithContentsOfURL:sndurl error:&error];
			if (_player == nil) {
				[self release];
				caml_failwith("can't create player");
			};
		} else {
			resource res;
			const char* c_fname = [fname cStringUsingEncoding:NSASCIIStringEncoding];

			if (!getResourceFd(c_fname, &res)) {
				[self release];
				char* fail_mes = (char*)malloc(255);
				sprintf(fail_mes, "can't obtain resource fd for av sound %s", c_fname);
				caml_failwith(fail_mes);
			}

			void* buf = malloc(res.length);
			if (read(res.fd, buf, res.length) != res.length) {
				[self release];
				char* fail_mes = (char*)malloc(255);
				sprintf(fail_mes, "can't read data for av sound %s", c_fname);
				caml_failwith(fail_mes);
			}

			NSData* sndData = [NSData dataWithBytesNoCopy:buf length:res.length];
			NSError* err = nil;

			_player = [[AVAudioPlayer alloc] initWithData:sndData error:&err];
			if (_player == nil) {
				[self release];
				caml_failwith("can't create player");
			}
		}

		_sound_stopped_handler = 0;
		_player.delegate = self;
		[_player prepareToPlay];
	}
	return self;
}


-(void)play:(value)stopHandler {
	_sound_stopped_handler = stopHandler;
	caml_register_generational_global_root(&_sound_stopped_handler);
  [_player play];
}


-(void)pause {
  [_player pause];
}


-(void)stop {
  [_player stop];
  _player.currentTime = 0;
	if (_sound_stopped_handler) {
		caml_remove_generational_global_root(&_sound_stopped_handler);
		_sound_stopped_handler = 0;
	}
}


-(BOOL)isPlaying {
  return _player.playing;
}


-(void)setLoop:(BOOL)value {
  _player.numberOfLoops = value ? -1 : 0;
}

-(float)volume {
  return _player.volume;
}


-(void)setVolume:(float)value {
  _player.volume = value;
}



#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
	if (_sound_stopped_handler) {
		//caml_acquire_runtime_system();
		caml_callback(_sound_stopped_handler, Val_unit);
		caml_remove_generational_global_root(&_sound_stopped_handler);
		_sound_stopped_handler = 0;
		//caml_release_runtime_system();
	};
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
	 NSLog(@"Error during sound decoding: %@", [error description]); // trhow error?
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
	[player pause];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
	[player play];
}

-(void)dealloc {
  [_player release];
	if (_sound_stopped_handler) caml_remove_generational_global_root(&_sound_stopped_handler);
  [super dealloc];
}

@end

#define AVPLAYER(v) ((AVSoundPlayerController**)Data_custom_val(v))
static void avplayer_finalize(value oplayer) {
	PRINT_DEBUG("av player finalize");
	AVSoundPlayerController *player = *AVPLAYER(oplayer);
  [player release];
}

struct custom_operations avplayer_ops = {
  "pointer to avsoundcontroller",
  avplayer_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/* create controller */
CAMLprim value ml_avsound_create_player(value fname) {
  CAMLparam1(fname);
	PRINT_DEBUG("create player");
  NSString * filename = [NSString stringWithCString:String_val(fname) encoding:NSASCIIStringEncoding];
  AVSoundPlayerController *playerController = [[AVSoundPlayerController alloc] initWithFilename:filename];

  if (playerController == nil) {
    raise_error("Error initializing LightningAVSoundPlayerController", NULL, 404);
  }

	value result = caml_alloc_custom(&avplayer_ops,sizeof(AVSoundPlayerController*),0,1);

	*AVPLAYER(result) = playerController;

  CAMLreturn(result);
}

/*
 * Release player controler
void ml_avsound_release(value playerController) {
  CAMLparam1(playerController);
	PRINT_DEBUG("avsound release");
  [(AVSoundPlayerController *)playerController release];
  CAMLreturn0;
}
*/

/*
 * Let's play
*/
value ml_avsound_play(value playerController, value stopHandler) {
  CAMLparam1(playerController);
	[*AVPLAYER(playerController) play:stopHandler];
  CAMLreturn(Val_unit);
}


/*
 * Pause
 */
value ml_avsound_pause(value playerController) {
  [*AVPLAYER(playerController) pause];
	return Val_unit;
}


/*
 * Stop
 */
value ml_avsound_stop(value playerController) {
  [*AVPLAYER(playerController) stop];
	return Val_unit;
}


/*
 * Set volume
 */
value ml_avsound_set_volume(value playerController, value volume) {
  [*AVPLAYER(playerController) setVolume: Double_val(volume)];
	return Val_unit;
}

/*
 * Get volume
 */
CAMLprim value ml_avsound_get_volume(value playerController) {
  return caml_copy_double([*AVPLAYER(playerController) volume]);
}


/*
 * Loop sound or not
 */
value ml_avsound_set_loop(value playerController, value loop) {
  [*AVPLAYER(playerController) setLoop: Bool_val(loop)];
	return Val_unit;
}


/*
 * Is playing
 */
CAMLprim value ml_avsound_is_playing(value playerController) {
	return Val_bool([*AVPLAYER(playerController) isPlaying]);
}
