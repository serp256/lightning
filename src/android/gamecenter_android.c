#include "lightning_android.h"
#include "engine_android.h"

#define CLS engine_find_class("ru/redspell/lightning/gamecenter/GameCenter");

static jclass gcCls = NULL;
static jobject jGameCenter = NULL;

static void clearGameCenter() {
	(*ML_ENV)->DeleteGlobalRef(ML_ENV,jGameCenter);
	jGameCenter = NULL;
}

value ml_gamecenter_init(value silent, value param) {
	CAMLparam2(silent, param);

	PRINT_DEBUG("1");

	// get factory class
	jclass gcManagerCls = engine_find_class("ru/redspell/lightning/gamecenter/Manager");
	if (gcManagerCls == NULL) {
        caml_failwith("GameCenterManager not found");
	}

	PRINT_DEBUG("2");

	// find static method createGameCenter
	jmethodID jCreateM = (*ML_ENV)->GetStaticMethodID(ML_ENV, gcManagerCls, "createGameCenter", "(I)Lru/redspell/lightning/gamecenter/GameCenter;");
	if (jCreateM == NULL) {
	    (*ML_ENV)->DeleteLocalRef(ML_ENV, gcManagerCls);
	    caml_failwith("createGameCenter method not found");
	}

	PRINT_DEBUG("3");


	// call static method createGameCenter, this creates GC Adapter instance
//	jobject gcLocalRef = (*env)->CallStaticObjectMethod(env, gcManagerCls, jCreateM);
	int kind = Int_val(param);
	jobject gcLocalRef = (*ML_ENV)->CallStaticObjectMethod(ML_ENV, gcManagerCls, jCreateM, kind);
	if (gcLocalRef == NULL) {
	    caml_failwith("failed to call createGameCenter method");
	}

	PRINT_DEBUG("4");


    // this is a real instance of CG Adapter. Now let's find its class
	jGameCenter = (*ML_ENV)->NewGlobalRef(ML_ENV, gcLocalRef);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, gcLocalRef);

	PRINT_DEBUG("5");

    jclass tmpCls = (*ML_ENV)->GetObjectClass(ML_ENV, jGameCenter);
	gcCls =  (*ML_ENV)->NewGlobalRef(ML_ENV, tmpCls);
	(*ML_ENV)->DeleteLocalRef(ML_ENV, tmpCls);

	PRINT_DEBUG("6");

	// call connect
    jmethodID jConnectM = (*ML_ENV)->GetMethodID(ML_ENV, gcCls, "connect", "()V");
		PRINT_DEBUG("jConnectM %d", jConnectM);
    if (jConnectM == NULL) {
        caml_failwith("Can't find connect method");
    }

    (*ML_ENV)->CallVoidMethod(ML_ENV, jGameCenter, jConnectM);

    PRINT_DEBUG("7");

	CAMLreturn(Val_true);
}

void gamecenter_connected(void *data) {
	caml_callback(*caml_named_value("game_center_initialized"), Val_true);
}

void gamecenter_failed(void *data) {
	clearGameCenter();
	caml_callback(*caml_named_value("game_center_initialized"), Val_false);
}

void gamecenter_disconnected(void *data) {
	caml_callback(*caml_named_value("game_center_disconnected"), Val_unit);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onConnected(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onConnected");
	RUN_ON_ML_THREAD(&gamecenter_connected, NULL);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onConnectFailed(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onConnectFailed");
	RUN_ON_ML_THREAD(&gamecenter_failed, NULL);
}

JNIEXPORT void JNICALL Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onDisconnected(JNIEnv *env, jobject this) {
	PRINT_DEBUG("Java_ru_redspell_lightning_gamecenter_Manager_00024Listener_onDisconnected");
	RUN_ON_ML_THREAD(&gamecenter_disconnected, NULL);
}


value ml_gamecenter_playerID(value param) {
	CAMLparam0();
	CAMLlocal1(res);
	PRINT_DEBUG("ml_playerID");

	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jGetPlayerIDM = NULL;
	if (!jGetPlayerIDM) {
		jclass gcCls = CLS;
		PRINT_DEBUG("TRY TO GET method ID");
		jGetPlayerIDM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"getPlayerID","()Ljava/lang/String;");
	};
	PRINT_DEBUG("PLAYER ID M: %ld",jGetPlayerIDM);
	jobject jPlayerID = (*ML_ENV)->CallObjectMethod(ML_ENV,jGameCenter,jGetPlayerIDM);
	if (jPlayerID) {
		const char *cpid = (*ML_ENV)->GetStringUTFChars(ML_ENV,jPlayerID,JNI_FALSE);
		res = caml_alloc(0,1);
		Store_field(res,0,caml_copy_string(cpid));
		(*ML_ENV)->ReleaseStringUTFChars(ML_ENV,jPlayerID,cpid);
	} else res = Val_none;
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jPlayerID);
	CAMLreturn(res);
}

static value convertPlayer(jobject jPlayer) {
	CAMLparam0();
	CAMLlocal3(res,pid,name);
	PRINT_DEBUG("GameCenter convert player");
	static jmethodID jGetPlayerIDM = NULL;
	static jmethodID jGetDisplayNameM = NULL;
	// Add Image here, maybe througt URL and extern image loader????
	if (!jGetPlayerIDM) {
		jclass jPlayerCls = engine_find_class("ru/redspell/lightning/gamecenter/Player");
		jGetPlayerIDM = (*ML_ENV)->GetMethodID(ML_ENV,jPlayerCls,"getPlayerId","()Ljava/lang/String;");
		jGetDisplayNameM = (*ML_ENV)->GetMethodID(ML_ENV,jPlayerCls,"getDisplayName","()Ljava/lang/String;");
	};
	PRINT_DEBUG("m1: %ld, m2: %ld",jGetDisplayNameM,jGetPlayerIDM);
	jstring jPlayerID = (*ML_ENV)->CallObjectMethod(ML_ENV,jPlayer,jGetPlayerIDM);
	jstring jDisplayName = (*ML_ENV)->CallObjectMethod(ML_ENV,jPlayer,jGetDisplayNameM);
	const char *cpid = (*ML_ENV)->GetStringUTFChars(ML_ENV,jPlayerID,JNI_FALSE);
	const char *cname = (*ML_ENV)->GetStringUTFChars(ML_ENV,jDisplayName,JNI_FALSE);
	pid = caml_copy_string(cpid);
	name = caml_copy_string(cname);
	res = caml_alloc_tuple(3);
	Store_field(res,0,pid);
	Store_field(res,1,name);
	Store_field(res,2,Val_none);
	(*ML_ENV)->ReleaseStringUTFChars(ML_ENV,jPlayerID,cpid);
	(*ML_ENV)->ReleaseStringUTFChars(ML_ENV,jDisplayName,cname);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jPlayerID);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jDisplayName);
	CAMLreturn(res);
}

value ml_gamecenter_current_player(value p) {
	CAMLparam0();
	CAMLlocal2(res, player);
	PRINT_DEBUG("GC current player");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jCurrentPlayerM = NULL;
	if (!jCurrentPlayerM) {
		jclass gcCls = CLS;
		jCurrentPlayerM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"currentPlayer","()Lru/redspell/lightning/gamecenter/Player;");
	};
	jobject jPlayer = (*ML_ENV)->CallObjectMethod(ML_ENV,jGameCenter,jCurrentPlayerM);
	if (jPlayer != NULL) {
		player = convertPlayer(jPlayer);
		(*ML_ENV)->DeleteLocalRef(ML_ENV,jPlayer);
		res = caml_alloc_small(0,1);
		Field(res,0) = player;
	} else res = Val_none;
	CAMLreturn(res);
}

value ml_gamecenter_report_leaderboard(value boardId, value score) {
	CAMLparam2(boardId, score);
	PRINT_DEBUG("GC report leaderboard");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jSubmitScoreM = NULL;
	if (!jSubmitScoreM) {
		jclass gcCls = CLS;
		jSubmitScoreM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"submitScore","(Ljava/lang/String;J)V");
	};
	jstring jid = (*ML_ENV)->NewStringUTF(ML_ENV,String_val(boardId));
	jlong jscore = Int64_val(score);
	(*ML_ENV)->CallVoidMethod(ML_ENV,jGameCenter,jSubmitScoreM,jid,jscore);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jid);
	CAMLreturn(Val_unit);
}

value ml_gamecenter_unlock_achievement(value name) {
	PRINT_DEBUG("GC unlock achievement");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jUnlockAchievementM = NULL;
	if (!jUnlockAchievementM) {
		jclass gcCls = CLS;
		jUnlockAchievementM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"unlockAchievement","(Ljava/lang/String;)V");
	};
	jstring jid = (*ML_ENV)->NewStringUTF(ML_ENV,String_val(name));
	(*ML_ENV)->CallVoidMethod(ML_ENV,jGameCenter,jUnlockAchievementM,jid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jid);
	return Val_unit;
}


value ml_gamecenter_show_achievements(value p) {
	PRINT_DEBUG("GC show achievements");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jShowAchievementsM = NULL;
	if (!jShowAchievementsM) {
		jclass gcCls = CLS;
		jShowAchievementsM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"showAchievements","()V");
	};
	(*ML_ENV)->CallVoidMethod(ML_ENV,jGameCenter,jShowAchievementsM);
	return Val_unit;
}


value ml_gamecenter_show_leaderboard(value board_id) {
	PRINT_DEBUG("GC show leaderboard");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jShowLeaderboardM = NULL;
	if (!jShowLeaderboardM) {
		jclass gcCls = CLS;
		jShowLeaderboardM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"showLeaderboard","(Ljava/lang/String;)V");
	};
	jstring jid = (*ML_ENV)->NewStringUTF(ML_ENV,String_val(board_id));
	(*ML_ENV)->CallVoidMethod(ML_ENV,jGameCenter,jShowLeaderboardM, jid);
	(*ML_ENV)->DeleteLocalRef(ML_ENV,jid);

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
	PRINT_DEBUG("GameCenter signout");
	if (jGameCenter == NULL) caml_failwith("GameCenter not initialized");
	static jmethodID jSignOutM = NULL;
	if (!jSignOutM) {
		jclass gcCls = CLS;
		jSignOutM = (*ML_ENV)->GetMethodID(ML_ENV,gcCls,"signOut","()V");
	};
	(*ML_ENV)->CallVoidMethod(ML_ENV,jGameCenter,jSignOutM);
	clearGameCenter(ML_ENV);
	CAMLreturn(Val_unit);
};
