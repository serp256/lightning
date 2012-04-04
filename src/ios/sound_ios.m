
#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

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

void ml_sound_init(value mlSessionCategory,value unit) {
	if (device) return;
	OSStatus result;
	result = AudioSessionInitialize(NULL, NULL, interruptionCallback, NULL);
	if (result != kAudioSessionNoError) raise_error("Could not initialize audio",NULL,result);
  UInt32 sessionCategory;
	switch (Val_int(mlSessionCategory)) {
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
}


// ALSOUND 

void ml_al_setMasterVolume(value mlVolume) {
	alListenerf(AL_GAIN, Double_val(mlVolume));
}

#define ALBUFFERID(v) ((uint*)Data_custom_val(v))
static void albuffer_finalize(value mlAlBufferID) {
	uint bufferID = *ALBUFFERID(mlAlBufferID);
	PRINT_DEBUG("albuffer finalize: %d",bufferID);
	checkOpenALError("finalize albuffer: %d",bufferID);
	alDeleteBuffers(1,&bufferID);
}

struct custom_operations albuffer_ops = {
  "pointer to alsound",
  albuffer_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


NSString* pathForResource(NSString *path) {
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
}

CAMLprim value ml_albuffer_create(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal2(mlBufferID,mlres);

	NSString *path = [NSString stringWithCString:String_val(mlpath) encoding:NSASCIIStringEncoding];
	NSString *fullPath = pathForResource(path);

	AudioFileID fileID = 0;
	void *soundBuffer = NULL;
	int   soundSize = 0;
	int   soundChannels = 0;
	int   soundFrequency = 0;
	double soundDuration = 0.0;

	OSStatus result = noErr;

	result = AudioFileOpenURL((CFURLRef) [NSURL fileURLWithPath:fullPath], kAudioFileReadPermission, 0, &fileID);
	
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
	
	mlBufferID = caml_alloc_custom(&albuffer_ops,sizeof(uint),soundSize,MAX_GC_MEM);
	*ALBUFFERID(mlBufferID) = bufferID;
	mlres = caml_alloc_tuple(2);
	Store_field(mlres,0,mlBufferID);
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

CAMLprim value ml_alsource_create(value mlAlBufferID) {
	CAMLparam1(mlAlBufferID);
	CAMLlocal1(mlAlSourceID);
	uint sourceID;
	alGenSources(1, &sourceID);
	uint bufferID = *ALBUFFERID(mlAlBufferID);
	alSourcei(sourceID, AL_BUFFER, bufferID);
	PRINT_DEBUG("created alsource: %d for buffer %d",sourceID,bufferID);
	checkOpenALError("create alsource: %d - %d",bufferID,sourceID);
	//mlAlSourceID = caml_alloc_custom(&alsource_ops,sizeof(uint),1,0);
	//*ALSOURCEID(mlAlSourceID) = sourceID;
	mlAlSourceID = caml_copy_int32(sourceID);
	CAMLreturn(mlAlSourceID);
}

void ml_alsource_play(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourcePlay(sourceID);
	PRINT_DEBUG("play source: %d",sourceID);
	// remove after debug
	checkOpenALError("play: %d",sourceID);
}

void ml_alsource_pause(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourcePause(sourceID);
	PRINT_DEBUG("pause alsource: %d",sourceID);
	// remove after debug
	checkOpenALError("pause: %d",sourceID);
}

void ml_alsource_stop(value mlAlSourceID) {
	//uint sourceID = *ALSOURCEID(mlAlSourceID);
	uint sourceID = Int32_val(mlAlSourceID);
	alSourceStop(sourceID);
	PRINT_DEBUG("stop alsource: %d",sourceID);
	// remove after debug
	checkOpenALError("play: %d",sourceID);
}

void ml_alsource_setLoop(value mlAlSourceID,value loop) {
	//alSourcei(*ALSOURCEID(mlAlSourceID), AL_LOOPING, Int_val(loop)); 
	alSourcei(Int32_val(mlAlSourceID), AL_LOOPING, Int_val(loop)); 
}

value ml_alsource_state(value mlAlSourceID) {
	ALint state;
	//alGetSourcei(*ALSOURCEID(mlAlSourceID), AL_SOURCE_STATE, &state);
	alGetSourcei(Int32_val(mlAlSourceID), AL_SOURCE_STATE, &state);
	int res;
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


void ml_alsource_delete(value mlAlSourceID) {
	uint sourceID = Int32_val(mlAlSourceID);
	alSourceStop(sourceID);
	alSourcei(sourceID, AL_BUFFER, 0);
	alDeleteSources(1, &sourceID);
}
