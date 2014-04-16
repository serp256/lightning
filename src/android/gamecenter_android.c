
#include "mlwrapper_android.h"

static jclass gcCls = NULL;


static jobject getGcCls(JNIEnv *env) {
	if (gcCls == NULL) {
		jclass cls = (*env)->FindClass(env, "ru/redspell/lightning/gamecenter/LightGameCenter");
		if (cls == NULL) caml_failwith("GameCenter not found");
		gcCls = (*env)->NewGlobalRef(env,cls);
		(*env)->DeleteLocalRef(env,cls);
	}
	return gcCls;
}



static jobject jGameCenter = NULL;


static void clearGameCenter(JNIEnv *env) {
	(*env)->DeleteGlobalRef(env,jGameCenter);
	jGameCenter = NULL;
}


value ml_gamecenter_init(value param) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("ml_game_center_init");
	
	// get factory class
	jclass gcManagerCls = (*env)->FindClass(env, "ru/redspell/lightning/gamecenter/LightGameCenterManager");
	if (gcManagerCls == NULL) {
        caml_failwith("GameCenterManager not found");
	}
	
	// find static method createGameCenter
	jmethodID jCreateM = (*env)->GetStaticMethodID(env, gcManagerCls, "createGameCenter", "(I)Lru/redspell/lightning/gamecenter/LightGameCenter;");
	if (jCreateM == NULL) {
	    (*env)->DeleteLocalRef(env, gcManagerCls);
	    caml_failwith("createGameCenter method not found");
	}
	
		
	// call static method createGameCenter, this creates GC Adapter instance
//	jobject gcLocalRef = (*env)->CallStaticObjectMethod(env, gcManagerCls, jCreateM);
	int kind = Int_val(param);
	jobject gcLocalRef = (*env)->CallStaticObjectMethod(env, gcManagerCls, jCreateM, kind);
	if (gcLocalRef == NULL) {
  	    (*env)->DeleteLocalRef(env, gcManagerCls);
  	    (*env)->DeleteLocalRef(env, jCreateM);
	    caml_failwith("failed to call createGameCenter method");  	    
	}


    // this is a real instance of CG Adapter. Now let's find its class
	jGameCenter = (*env)->NewGlobalRef(env, gcLocalRef);
	(*env)->DeleteLocalRef(env, gcLocalRef);

    jclass tmpCls = (*env)->GetObjectClass(env, jGameCenter);
	gcCls =  (*env)->NewGlobalRef(env, tmpCls);
	(*env)->DeleteLocalRef(env, tmpCls);
	

	// call connect 
    jmethodID jConnectM = (*env)->GetMethodID(env, gcCls, "connect", "()V");
    if (jConnectM == NULL) {
        caml_failwith("Can't find connect method");   
    }

    (*env)->CallVoidMethod(env, jGameCenter, jConnectM);
    (*env)->DeleteLocalRef(env, jConnectM);
	
	return Val_true;
}


JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_LightGameCenterManager_00024ConnectionSuccessCallbackRunnable_run(JNIEnv *env, jobject this) {
	value *ml_gamecenter_initialized = caml_named_value("game_center_initialized");
	caml_callback(*ml_gamecenter_initialized,Val_true);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_LightGameCenterManager_00024ConnectionFailedCallbackRunnable_run(JNIEnv *env, jobject this) {
	value *ml_gamecenter_initialized = caml_named_value("game_center_initialized");
	clearGameCenter(env);
	caml_callback(*ml_gamecenter_initialized,Val_false);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_LightGameCenterManager_00024ConnectionDisconnectedCallbackRunnable_run(JNIEnv *env, jobject this) {
	value *ml_gamecenter_disconnected = caml_named_value("game_center_disconnected");
	caml_callback(*ml_gamecenter_disconnected,Val_unit);
}


value ml_gamecenter_playerID(value param) {
	CAMLparam0();
	CAMLlocal1(res);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("ml_playerID");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jGetPlayerIDM = NULL;
	if (!jGetPlayerIDM) {
		jclass gcCls = getGcCls(env);
		PRINT_DEBUG("TRY TO GET method ID");
		jGetPlayerIDM = (*env)->GetMethodID(env,gcCls,"getPlayerID","()Ljava/lang/String;");
	};
	PRINT_DEBUG("PLAYER ID M: %ld",jGetPlayerIDM);
	jobject jPlayerID = (*env)->CallObjectMethod(env,jGameCenter,jGetPlayerIDM);
	if (jPlayerID) {
		const char *cpid = (*env)->GetStringUTFChars(env,jPlayerID,JNI_FALSE);
		res = caml_alloc(0,1);
		Store_field(res,0,caml_copy_string(cpid));
		(*env)->ReleaseStringUTFChars(env,jPlayerID,cpid);
	} else res = Val_none;
	(*env)->DeleteLocalRef(env,jPlayerID);
	CAMLreturn(res); 
}

static value convertPlayer(JNIEnv *env, jobject jPlayer) {
	CAMLparam0();
	CAMLlocal3(res,pid,name);
	PRINT_DEBUG("GameCenter convert player");
	static jmethodID jGetPlayerIDM = NULL;
	static jmethodID jGetDisplayNameM = NULL;
	// Add Image here, maybe througt URL and extern image loader????
	if (!jGetPlayerIDM) {
		jclass jPlayerCls = (*env)->FindClass(env,"ru/redspell/lightning/gamecenter/LightGameCenterPlayer");
		jGetPlayerIDM = (*env)->GetMethodID(env,jPlayerCls,"getPlayerId","()Ljava/lang/String;");
		jGetDisplayNameM = (*env)->GetMethodID(env,jPlayerCls,"getDisplayName","()Ljava/lang/String;");
		(*env)->DeleteLocalRef(env,jPlayerCls);
	};
	PRINT_DEBUG("m1: %ld, m2: %ld",jGetDisplayNameM,jGetPlayerIDM);
	jstring jPlayerID = (*env)->CallObjectMethod(env,jPlayer,jGetPlayerIDM);
	jstring jDisplayName = (*env)->CallObjectMethod(env,jPlayer,jGetDisplayNameM);
	const char *cpid = (*env)->GetStringUTFChars(env,jPlayerID,JNI_FALSE);
	const char *cname = (*env)->GetStringUTFChars(env,jDisplayName,JNI_FALSE);
	pid = caml_copy_string(cpid);
	name = caml_copy_string(cname);
	res = caml_alloc_tuple(3);
	Store_field(res,0,pid);
	Store_field(res,1,name);
	Store_field(res,2,Val_none);
	(*env)->ReleaseStringUTFChars(env,jPlayerID,cpid);
	(*env)->ReleaseStringUTFChars(env,jDisplayName,cname);
	(*env)->DeleteLocalRef(env,jPlayerID);
	(*env)->DeleteLocalRef(env,jDisplayName);
	CAMLreturn(res);
}

value ml_gamecenter_current_player(value p) {
	CAMLparam0();
	CAMLlocal1(player);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GC current player");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jCurrentPlayerM = NULL;
	if (!jCurrentPlayerM) { 
		jclass gcCls = getGcCls(env);
		jCurrentPlayerM = (*env)->GetMethodID(env,gcCls,"currentPlayer","()Lru/redspell/lightning/gamecenter/LightGameCenterPlayer;");
	};
	jobject jPlayer = (*env)->CallObjectMethod(env,jGameCenter,jCurrentPlayerM);
	value res;
	if (jPlayer != NULL) {
		player = convertPlayer(env,jPlayer);
		(*env)->DeleteLocalRef(env,jPlayer);
		res = caml_alloc_small(0,1);
		Field(res,0) = player;
	} else res = Val_none;
	CAMLreturn(res);
}

value ml_gamecenter_report_leaderboard(value boardId, value score) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GC report leaderboard");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jSubmitScoreM = NULL;
	if (!jSubmitScoreM) { 
		jclass gcCls = getGcCls(env);
		jSubmitScoreM = (*env)->GetMethodID(env,gcCls,"submitScore","(Ljava/lang/String;J)V");
	};
	jstring jid = (*env)->NewStringUTF(env,String_val(boardId));
	jlong jscore = Int64_val(score);  
	(*env)->CallVoidMethod(env,jGameCenter,jSubmitScoreM,jid,jscore);
	(*env)->DeleteLocalRef(env,jid);
	return Val_unit;
}

value ml_gamecenter_unlock_achievement(value name) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GC unlock achievement");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jUnlockAchievementM = NULL;
	if (!jUnlockAchievementM) { 
		jclass gcCls = getGcCls(env);
		jUnlockAchievementM = (*env)->GetMethodID(env,gcCls,"unlockAchievement","(Ljava/lang/String;)V");
	};
	jstring jid = (*env)->NewStringUTF(env,String_val(name));
	(*env)->CallVoidMethod(env,jGameCenter,jUnlockAchievementM,jid);
	(*env)->DeleteLocalRef(env,jid);
	return Val_unit;
}


value ml_gamecenter_show_achievements(value p) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GC show achievements");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jShowAchievementsM = NULL;
	if (!jShowAchievementsM) { 
		jclass gcCls = getGcCls(env);
		jShowAchievementsM = (*env)->GetMethodID(env,gcCls,"showAchievements","()V");
	};
	(*env)->CallVoidMethod(env,jGameCenter,jShowAchievementsM);
	return Val_unit;
}


value ml_gamecenter_show_leaderboard(value board_id) {
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GC show leaderboard");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jShowLeaderboardM = NULL;
	if (!jShowLeaderboardM) { 
		jclass gcCls = getGcCls(env);
		jShowLeaderboardM = (*env)->GetMethodID(env,gcCls,"showLeaderboard","(Ljava/lang/String;)V");
	};
	jstring jid = (*env)->NewStringUTF(env,String_val(board_id));
	(*env)->CallVoidMethod(env,jGameCenter,jShowLeaderboardM, jid);
	(*env)->DeleteLocalRef(env,jid);

	return Val_unit;
}

value ml_gamecenter_get_friends_identifiers(value f) {
	return Val_unit;
}

value ml_gamecenter_load_users_info(value f) {
	return Val_unit;
}


value ml_gamecenter_signout(value p) {
	CAMLparam0();
	CAMLlocal1(res);
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	PRINT_DEBUG("GameCenter signout");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jSignOutM = NULL;
	if (!jSignOutM) {
		jclass gcCls = getGcCls(env);
		jSignOutM = (*env)->GetMethodID(env,gcCls,"signOut","()V");
	};
	(*env)->CallVoidMethod(env,jGameCenter,jSignOutM);
	clearGameCenter(env);
	CAMLreturn(Val_unit);
};
