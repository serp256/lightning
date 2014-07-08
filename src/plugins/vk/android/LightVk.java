package ru.redspell.lightning.plugins;

import ru.redspell.lightning.LightActivity;
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
	private static class Callback implements Runnable {
		protected int success;
		protected int fail;

		protected native void freeCallbacks(int success, int fail);

		public Callback(int success, int fail) {
			this.success = success;
			this.fail = fail;
		}

		public void run() {
			freeCallbacks(success, fail);
		}
	}

	private static class AuthSuccess extends Callback {
		public AuthSuccess(int success, int fail) {
			super(success, fail);
		}

		public native void nativeRun(int cb);

		public void run() {
			nativeRun(success);
			super.run();
		}
	}

	private static class Fail extends Callback {
		private String reason;

		public Fail(int success, int fail, String reason) {
			super(success, fail);
			this.reason = reason;
		}

		public native void nativeRun(int cb, String reason);

		public void run() {
			nativeRun(fail, reason);
			super.run();
		}
	}

	private static class FriendsSuccess extends Callback {
		private String[] ids;
		private String[] names;
		private int[] genders;

		public FriendsSuccess(int success, int fail, String[] ids, String[] names, int[] genders) {
			super(success, fail);
			this.ids = ids;
			this.names = names;
			this.genders = genders;
		}

		public native void nativeRun(int cb, String[] ids, String[] names, int[] genders);

		public void run() {
			nativeRun(success, ids, names, genders);
			super.run();
		}
	}

	private static class VKSdkListener extends com.vk.sdk.VKSdkListener {
		private int success;
		private int fail;

		public VKSdkListener(int success, int fail) {
			this.success = success;
			this.fail = fail;
		}

		public void onCaptchaError(VKError captchaError) {}
		public void onTokenExpired(VKAccessToken expiredToken) {}

		public void onAccessDenied(VKError authorizationError) {
			LightActivity.instance.lightView.queueEvent(new Fail(success, fail, authorizationError.errorMessage + ": " + authorizationError.errorReason));
		}

		public void onReceiveNewToken(VKAccessToken newToken) {
			LightActivity.instance.lightView.queueEvent(new AuthSuccess(success, fail));
		}

		public void onAcceptUserToken(VKAccessToken token) {}
		public void onRenewAccessToken(VKAccessToken token) {}			
	}

	private static class UiLifecycleHelper implements ru.redspell.lightning.IUiLifecycleHelper {
		public void onCreate(Bundle savedInstanceState) {};

		public void onResume() {
			VKUIHelper.onResume(LightActivity.instance);
		};

		public void onActivityResult(int requestCode, int resultCode, Intent data) {
			VKUIHelper.onActivityResult(requestCode, resultCode, data);
		};

		public void onSaveInstanceState(Bundle outState) {};
		public void onPause() {};
		public void onStop() {};

		public void onDestroy() {
			VKUIHelper.onDestroy(LightActivity.instance); 
		};
	}

	private static boolean authorized = false;

	public static void authorize(String appid, String[] permissions, int success, int fail) {
		if (!authorized) {
			authorized = true;
			LightActivity.instance.addUiLifecycleHelper(new UiLifecycleHelper());
			/*
			 cause vk authorization is called after first LightActivity onResume call,
			 LightVk lifecycle helper misses this call and didn't save activity instance for internal purposes
			 to make VKSdk work correctly we need to emulate this call
			*/
			VKUIHelper.onResume(LightActivity.instance);
			VKSdk.initialize(new VKSdkListener(success, fail), appid);
			VKSdk.authorize(permissions, false, false);
		}
	}

	public static void friends(final int success, final int fail) {
		VKRequest request = new VKRequest("friends.get", VKParameters.from(VKApiConst.FIELDS, "sex"));
		request.executeWithListener(new VKRequestListener() { 
			@Override 
			public void onComplete(VKResponse response) {
				try {
					JSONObject resp = response.json.getJSONObject("response");
					int cnt = resp.getInt("count");
					JSONArray items = resp.getJSONArray("items");
					String ids[] = new String[cnt];
					String names[] = new String[cnt];
					int genders[] = new int[cnt];

					for (int i = 0; i < cnt; i++) {
						JSONObject item = items.getJSONObject(i);
						ids[i] = item.getString("id");
						names[i] = item.getString("last_name") + " " + item.getString("first_name");
						genders[i] = item.getInt("sex");
					}

					LightActivity.instance.lightView.queueEvent(new FriendsSuccess(success, fail, ids, names, genders));
				} catch (org.json.JSONException e) {
					LightActivity.instance.lightView.queueEvent(new Fail(success, fail, "wrong format of response on friends request"));
				}
			}

			@Override 
			public void onError(VKError error) {
				LightActivity.instance.lightView.queueEvent(new Fail(success, fail, error.errorMessage + ": " + error.errorReason));
			}

			@Override 
			public void attemptFailed(VKRequest request, int attemptNumber, int totalAttempts) { 
			}
		});
	}
}