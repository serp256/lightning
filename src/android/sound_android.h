

value ml_alsoundLoad(value path);
value ml_alsoundPlay(value soundId, value vol, value loop);
value ml_alsoundPause(value streamId);
value ml_alsoundStop(value streamId);
value ml_alsoundSetVolume(value streamId, value vol);
value ml_alsoundSetLoop(value streamId, value loop);

void sound_pause(JNIEnv *env);
void sound_resume(JNIEnv *env);
