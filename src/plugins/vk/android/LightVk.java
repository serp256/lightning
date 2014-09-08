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

	private static class FriendsSuccess extends Callback {
		private String[] ids;
		private String[] names;
		private int[] genders;
		private String[] photos;

		public FriendsSuccess(int success, int fail, String[] ids, String[] names, int[] genders, String[] photos) {
			super(success, fail);
			this.ids = ids;
			this.names = names;
			this.genders = genders;
			this.photos = photos;
		}

		public native void nativeRun(int success, int fail, String[] ids, String[] names, int[] genders, String[] photos);

		public void run() {
			nativeRun(success, fail, ids, names, genders, photos);
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
			Log.d("LIGHTNING", "onReceiveNewToken");
			newToken.saveTokenToSharedPreferences(Lightning.activity, "lightning_nativevk_token");
			authorized = true;
			(new AuthSuccess(success, fail)).run();
		}

		public void onAcceptUserToken(VKAccessToken token) {
			token.saveTokenToSharedPreferences(Lightning.activity, "lightning_nativevk_token");
			Log.d("LIGHTNING", "onAcceptUserToken");
		}

		public void onRenewAccessToken(VKAccessToken token) {
			token.saveTokenToSharedPreferences(Lightning.activity, "lightning_nativevk_token");
			Log.d("LIGHTNING", "onRenewAccessToken");
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

	public static void authorize(String appid, String[] permissions, int success, int fail, boolean force) {
		Log.d("LIGHTNING", "!!!authorized " + authorized);

		if (authorized) {
			(new AuthSuccess(success, fail)).run();
			return;
		}

		if (!helperAdded) {
			helperAdded =true;
			Lightning.activity.addUiLifecycleHelper(new UiLifecycleHelper());
			/*
			cause vk authorization is called after first LightActivity onResume call,
			LightVk lifecycle helper misses this call and didn't save activity instance for internal purposes
			to make VKSdk work correctly we need to emulate this call
			*/
			VKUIHelper.onResume(Lightning.activity);
		}

		VKSdk.initialize(new VKSdkListener(success, fail), appid);
		VKAccessToken token = VKAccessToken.tokenFromSharedPreferences(Lightning.activity, "lightning_nativevk_token");

		if (token == null || token.isExpired() || force) {
			Log.d("LIGHTNING", "no token or it is expied");
			VKSdk.authorize(permissions, false, false);
		} else {
			Log.d("LIGHTNING", "has token");
			VKSdk.setAccessToken(token, false);
		}
	}

	public static String token() {
		return VKSdk.getAccessToken().accessToken;
	}

	public static String uid() {
		return VKSdk.getAccessToken().userId;
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
					String ids[] = new String[cnt];
					String names[] = new String[cnt];
					int genders[] = new int[cnt];
					String photos[] = new String[cnt];

					for (int i = 0; i < cnt; i++) {
						JSONObject item = items.getJSONObject(i);
						ids[i] = item.getString("id");
						names[i] = item.getString("last_name") + " " + item.getString("first_name");
						genders[i] = item.getInt("sex");
						photos[i] = item.getString("photo_max");
					}

					Log.d("LIGHTNING", "call success cnt " + cnt);
					(new FriendsSuccess(success, fail, ids, names, genders, photos)).run();
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
		usersRequests(new VKRequest("friends.get", VKParameters.from(VKApiConst.FIELDS, "sex,photo_max")), success, fail);
	}

	public static void users(String ids, int success, int fail) {
		usersRequests(new VKRequest("users.get", VKParameters.from(VKApiConst.FIELDS, "sex,photo_max", VKApiConst.USER_IDS, ids)), success, fail);
	}
}
