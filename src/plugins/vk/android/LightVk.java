package ru.redspell.lightning.plugins;

import ru.redspell.lightning.Lightning;
import com.vk.sdk.VKSdk;
import com.vk.sdk.api.VKError;
import com.vk.sdk.VKAccessToken;
import com.vk.sdk.VKUIHelper;
import com.vk.sdk.api.VKRequest;
import com.vk.sdk.api.VKRequest.VKRequestListener;
import com.vk.sdk.api.VKResponse;
import com.vk.sdk.api.VKApiConst;
import com.vk.sdk.api.VKParameters;
import android.os.Bundle;
import org.json.JSONObject;
import org.json.JSONArray;
import android.content.Intent;
import ru.redspell.lightning.utils.Log;

public class LightVk {
	private static abstract class Callback implements Runnable {
		protected int success;
		protected int fail;

		public abstract void run();

		public Callback(int success, int fail) {
			this.success = success;
			this.fail = fail;
		}
	}

	private static class AuthSuccess extends Callback {
		public AuthSuccess(int success, int fail) {
			super(success, fail);
		}

		public native void nativeRun(int success, int fail);

		public void run() {
			nativeRun(success, fail);
		}
	}

	private static class Fail extends Callback {
		private String reason;

		public Fail(int success, int fail, String reason) {
			super(success, fail);
			this.reason = reason;
		}

		public native void nativeRun(int fail, String reason, int success);

		public void run() {
			nativeRun(fail, reason, success);
		}
	}

	private static class Friend {
		private String id;
		private String name;
		private int gender;
		private String photo;
		private boolean online;
		private int lastSeen;

		public Friend(String id, String name, int gender, String photo, boolean online, int lastSeen) {
			this.id = id;
			this.name = name;
			this.gender = gender;
			this.photo = photo;
			this.online = online;
			this.lastSeen = lastSeen;
		}
	}

	private static class FriendsSuccess extends Callback {
		private Friend[] friends;

		public FriendsSuccess(int success, int fail, Friend[] friends) {
			super(success, fail);
			this.friends = friends;
		}

		public native void nativeRun(int success, int fail, Friend[] friends);

		public void run() {
			nativeRun(success, fail, friends);
		}
	}

	private static boolean authorized = false;

	private static class VKSdkListener extends com.vk.sdk.VKSdkListener {
		private int success;
		private int fail;

		public VKSdkListener(int success, int fail) {
			this.success = success;
			this.fail = fail;
		}

		public void onCaptchaError(VKError captchaError) {
			Log.d("LIGHTNING", "onCaptchaError");
		}

		public void onTokenExpired(VKAccessToken expiredToken) {
			Log.d("LIGHTNING", "onTokenExpired");
		}

		public void onAccessDenied(VKError authorizationError) {
			Log.d("LIGHTNING", "onAccessDenied " + authorizationError.errorMessage + " " + authorizationError.errorReason);
			authorized = false;
			(new Fail(success, fail, authorizationError.errorMessage + ": " + authorizationError.errorReason)).run();
		}

		public void onReceiveNewToken(VKAccessToken newToken) {
			Log.d("LIGHTNING", "onReceiveNewToken " + newToken.accessToken);
			authorized = true;
			(new AuthSuccess(success, fail)).run();
		}

		public void onAcceptUserToken(VKAccessToken token) {
			Log.d("LIGHTNING", "onAcceptUserToken");
		}

		public void onRenewAccessToken(VKAccessToken token) {
			Log.d("LIGHTNING", "onRenewAccessToken");
			authorized = true;
			(new AuthSuccess(success, fail)).run();
		}
	}

	private static class UiLifecycleHelper implements ru.redspell.lightning.IUiLifecycleHelper {
		public void onCreate(Bundle savedInstanceState) {};

		public void onResume() {
			VKUIHelper.onResume(Lightning.activity);
		};

		public void onActivityResult(int requestCode, int resultCode, Intent data) {
			Log.d("LIGHTNING", "vk sdk onActivityResult");
			VKUIHelper.onActivityResult(requestCode, resultCode, data);
		};

		public void onSaveInstanceState(Bundle outState) {};
		public void onPause() {};
		public void onStop() {};

		public void onDestroy() {
			VKUIHelper.onDestroy(Lightning.activity);
		};
	}

	private static boolean helperAdded = false;
	private static boolean sdkListenerAdded = false;

	public static void authorize(String appid, String[] permissions, int success, int fail, boolean force) {
		Log.d("LIGHTNING", "!!!authorized " + authorized + " force " + force);

		if (authorized && !force) {
			(new AuthSuccess(success, fail)).run();
			return;
		}

		Log.d("LIGHTNING", "helperAdded " + helperAdded);
		if (!helperAdded) {
			helperAdded =true;
			Log.d("LIGHTNING", "adding lifecycle helper");
			Lightning.activity.addUiLifecycleHelper(new UiLifecycleHelper());
			/*
			cause vk authorization is called after first LightActivity onResume call,
			LightVk lifecycle helper misses this call and didn't save activity instance for internal purposes
			to make VKSdk work correctly we need to emulate this call
			*/
			VKUIHelper.onResume(Lightning.activity);
		}

		VKSdk.initialize(new VKSdkListener(success, fail), appid);

		if (force) {
			VKSdk.logout();
		}

		boolean wakedUp = VKSdk.wakeUpSession();

		if (!wakedUp) {
			Log.d("LIGHTNING", "no token or it is expied");
			VKSdk.authorize(permissions, false, false);
		} else {
			Log.d("LIGHTNING", "has token");
			(new AuthSuccess(success, fail)).run();
		}
	}

	public static String token() {
		return VKSdk.getAccessToken().accessToken;
	}

	public static String uid() {
		return VKSdk.getAccessToken().userId;
	}

	public static void logout() {
		Log.d("LIGHTNING", "vk logout");
		VKSdk.logout();
	}

	private static void usersRequests(VKRequest request, final int success, final int fail) {
		Log.d("LIGHTNING", "usersRequests CALL");
		request.executeWithListener(new VKRequestListener() {
			@Override
			public void onComplete(VKResponse response) {
				try {
					Log.d("LIGHTNING", "response " + response.json.toString());

					JSONObject resp = response.json.optJSONObject("response");
					JSONArray items;

					if (resp != null) {
						items = resp.getJSONArray("items");
					} else {
						items = response.json.getJSONArray("response");
					}

					int cnt = items.length();
					Friend[] friends = new Friend[cnt];
					Log.d("LIGHTNING", "items " + items);

					for (int i = 0; i < cnt; i++) {
						Log.d("LIGHTNING", "item " + i  );
						JSONObject item = items.getJSONObject(i);
						Log.d("LIGHTNING", "item " + item  );

						friends[i] = new Friend(item.getString("id"), item.getString("last_name") + " " + item.getString("first_name"), item.getInt("sex"),
													item.getString("photo_max"), item.has("online") ? item.getInt("online") == 1 : false, item.has("last_seen") ? item.getJSONObject("last_seen").getInt("time") : 0);
					}

					Log.d("LIGHTNING", "call success cnt " + cnt);
					(new FriendsSuccess(success, fail, friends)).run();
				} catch (org.json.JSONException e) {
					Log.d("LIGHTNING", "Friends onComplete Fail");
					(new Fail(success, fail, "wrong format of response on friends request")).run();
				}
			}

			@Override
			public void onError(VKError error) {
				Log.d("LIGHTNING", "Friends onError");
				(new Fail(success, fail, error.errorMessage + ": " + error.errorReason)).run();
			}

			@Override
			public void attemptFailed(VKRequest request, int attemptNumber, int totalAttempts) {
				Log.d("LIGHTNING", "Friends attemptFailed");
			}
		});
	}

	public static void friends(int success, int fail) {
		usersRequests(new VKRequest("friends.get", VKParameters.from(VKApiConst.FIELDS, "sex,photo_max,last_seen,online")), success, fail);
	}

	public static void users(String ids, int success, int fail) {
		usersRequests(new VKRequest("users.get", VKParameters.from(VKApiConst.FIELDS, "sex,photo_max,last_seen,online,online_app,online_mobile", VKApiConst.USER_IDS, ids)), success, fail);
	}


	private static void appRequests (VKRequest request, final int success, final int fail) {
		Log.d("LIGHTNING", "appRequests CALL");
		/*
		request.executeWithListener(new VKRequestListener() {
			@Override
			public void onComplete(VKResponse response) {
					Log.d("LIGHTNING", "response " + response.json.toString());
			}

			@Override
			public void onError(VKError error) {
				Log.d("LIGHTNING", "appRequest onError " + error.apiError.errorMessage + ": " + error.apiError.errorReason);
			}

			@Override
			public void attemptFailed(VKRequest request, int attemptNumber, int totalAttempts) {
				Log.d("LIGHTNING", "appRequest attemptFailed");
			}
		});
		*/
	}
	public static void apprequest (int success, int fail, String uid) {
		/*
		appRequests(new VKRequest("apps.sendRequest", VKParameters.from("text","test app request", "type", "request","name","app_req_name","key","app_req_key",VKApiConst.USER_ID, uid)), success, fail);
		*/
	}
}
