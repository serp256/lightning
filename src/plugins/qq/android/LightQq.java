package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;

import com.tencent.connect.common.Constants;
import com.tencent.tauth.IUiListener;
import com.tencent.tauth.UiError;
import com.tencent.tauth.Tencent;
import com.tencent.connect.share.QzoneShare;
import com.tencent.open.SocialConstants;

import android.content.Intent;
import android.os.Bundle;
import org.json.JSONObject;
import org.json.JSONException;
import java.io.IOException;
import java.net.*;
import org.apache.http.conn.*;
import android.view.View;
import java.util.ArrayList;

class LightQq {
	public static Tencent mTencent;
	private static boolean helperAdded = false;
	private static String app_id;
	private static int success;
	private static int fail;

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

	private static class BaseUiListener implements IUiListener { 
		@Override
    public void onComplete(Object response) {
			Log.d("LIGHTNING","onComplete");
      doComplete((JSONObject)response);
    }

		protected void doComplete(JSONObject values) { 
		} 

		@Override 
		public void onError(UiError e) { 
			Log.d("LIGHTNING", "On Error code:" + e.errorCode + ", msg:"        + e.errorMessage + ", detail:" + e.errorDetail);  
		}

		@Override 
		public void onCancel() { 
			Log.d ("LIGHTNING","onCancel"); 
		} 
		
	}

  static IUiListener loginListener = new BaseUiListener() {
        @Override
        protected void doComplete(JSONObject values) {
          Log.d("LIGHTNING", "Login completed: " + values.toString() );

					try {
								String token = values.getString(Constants.PARAM_ACCESS_TOKEN);
								String expires = values.getString(Constants.PARAM_EXPIRES_IN);
								String openId = values.getString(Constants.PARAM_OPEN_ID);

								mTencent.setAccessToken(token, expires);
								mTencent.setOpenId(openId);
					} catch(java.lang.Exception e) { }
					(new AuthSuccess(success, fail)).run();
        }

				@Override 
				public void onError(UiError e) { 
					Log.d("LIGHTNING", "On Error code:" + e.errorCode + ", msg:"        + e.errorMessage + ", detail:" + e.errorDetail);  
					String message = "On Error code:" + e.errorCode + ", msg:"        + e.errorMessage + ", detail:" + e.errorDetail;
					(new Fail(success, fail, message)).run();
				}

				@Override 
				public void onCancel() { 
					Log.d ("LIGHTNING","onCancel"); 
					(new Fail(success, fail, "Cancelled")).run();
				} 
	};

	public static void init (final String appId, final String uid, final String token, final String expires) {
		app_id = appId;
		Log.d("LIGHTNING", "uid = " + (uid == null? "null":uid));
		if (!helperAdded) {
			helperAdded  = true;
			Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
					public void onCreate(Bundle savedInstanceState) { }

					public void onResume() { }

					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						Log.d ("LIGHTNING", "QQ: onActivityResult");
						 if (requestCode == Constants.REQUEST_LOGIN || requestCode == Constants.REQUEST_APPBAR) {
							 Tencent.onActivityResultData(requestCode,resultCode,data,loginListener);
						 }
						 if (requestCode == Constants.REQUEST_SOCIAL_API) {
							 Tencent.onActivityResultData(requestCode,resultCode,data,new BaseUiListener());
						 }
					}

					public void onSaveInstanceState(Bundle outState) {}

					public void onPause() { }

					public void onStop() {}
					public void onDestroy() {}
					public void onStart() {}
			});
		}
		Lightning.activity.runOnUiThread(new Runnable() {
				@Override
				public void run() {

					if (mTencent == null) {
						mTencent = Tencent.createInstance(appId, Lightning.activity.getApplicationContext());
						if (uid != null && token !=null) {
							mTencent.setAccessToken(token, expires);
							mTencent.setOpenId(uid);
						}
					}
				}
		});
	}

	public static void authorize (final int s, final int f, boolean force) {
		success = s;
		fail = f;
		Log.d ("LIGHTNING", "force " + force);
		if (!helperAdded) {
			helperAdded  = true;
			Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
					public void onCreate(Bundle savedInstanceState) {
			}

					public void onResume() { }

					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						 if (requestCode == Constants.REQUEST_LOGIN ||
							 requestCode == Constants.REQUEST_APPBAR) {
							 Tencent.onActivityResultData(requestCode,resultCode,data,loginListener);
							 }

					}

					public void onSaveInstanceState(Bundle outState) {}

					public void onPause() { }

					public void onStop() {}
					public void onDestroy() {}
					public void onStart() {}
			});
		}
		if (mTencent == null) {
			(new Fail(success, fail, "Should call QQ.init first")).run();
		}
		else {
			if (force) {
				mTencent.logout(Lightning.activity);
			}

			if (!mTencent.isSessionValid()) {
					Lightning.activity.runOnUiThread(new Runnable() {
							@Override
							public void run() {
								mTencent.login(Lightning.activity, "all", loginListener);

							}
					});
			}
			else {
				(new AuthSuccess(success, fail)).run();
			}
		}
	}

	public static String token() {
		if (mTencent != null) {
			return mTencent.getAccessToken();
		}
		else {
			return "";
		}
	}

	public static String uid() {
		if (mTencent != null) {
			return mTencent.getOpenId();
		}
		else {
			return "";
		}
	}

	public static void logout() {
		Log.d("LIGHTNING", "qq logout");
		mTencent.logout(Lightning.activity);
	}

	public static void invite() {
			 /*
			 Log.d ("LIGHTNING","send invite");
			final Bundle params = new Bundle();

			params.putString(SocialConstants.PARAM_APP_ICON, "http://imgcache.qq.com/qzone/space_item/pre/0/66768.gif");
			params.putString(SocialConstants.PARAM_APP_DESC, "AndroidSdk_1_3: invite description!");
			params.putString(SocialConstants.PARAM_APP_CUSTOM, "AndroidSdk_1_3: invite message!");
			params.putString(SocialConstants.PARAM_ACT, "进入应用");
			Lightning.activity.runOnUiThread(new Runnable() {
					@Override
				public void run() {
					mTencent.invite(Lightning.activity, params, new BaseUiListener());	
				}
			});
    }
		else {
			Log.d ("LIGHTNING","cant send invite");
		}
		*/
			 /*
			 final Bundle params = new Bundle();
		 params.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_APP);
		 params.putString(QQShare.SHARE_TO_QQ_TITLE, "title");
		 params.putString(QQShare.SHARE_TO_QQ_SUMMARY,  "summary");
		 params.putString(QQShare.SHARE_TO_QQ_IMAGE_URL, "http://imgcache.qq.com/qzone/space_item/pre/0/66768.gif");
		 params.putString(QQShare.SHARE_TO_QQ_APP_NAME, ("tencent"+app_id));
		 mTencent.shareToQQ(Lightning.activity, params, new BaseUiListener());
		 */

			final Bundle params = new Bundle();

			ArrayList<String> images = new ArrayList<String> ();
			 params.putInt(QzoneShare.SHARE_TO_QZONE_KEY_TYPE, QzoneShare.SHARE_TO_QZONE_TYPE_IMAGE_TEXT );
		 params.putString(QzoneShare.SHARE_TO_QQ_TITLE, "loser");//必填
		 params.putString(QzoneShare.SHARE_TO_QQ_SUMMARY, "I completed the level 1 with 0 scores!");//选填
		 params.putString(QzoneShare.SHARE_TO_QQ_TARGET_URL, "http://android.myapp.com/myapp/detail.htm?apkName=com.tencent.tmgp.redspell.shuzidahai");//必填

		 images.add("http://imgcache.qq.com/qzone/space_item/pre/0/66768.gif");
		 params.putStringArrayList(QzoneShare.SHARE_TO_QQ_IMAGE_URL, images);

		 Log.d ("LIGHTNING","send invite");
		 mTencent.shareToQzone(Lightning.activity, params, new BaseUiListener());

 }

public static void share(String title, String summary, String url, String imageUrl) {
     if (mTencent != null && mTencent.isReady()) {

			final Bundle params = new Bundle();

			ArrayList<String> images = new ArrayList<String> ();
			images.add(imageUrl);
			 params.putInt(QzoneShare.SHARE_TO_QZONE_KEY_TYPE, QzoneShare.SHARE_TO_QZONE_TYPE_IMAGE_TEXT );
			 params.putString(QzoneShare.SHARE_TO_QQ_TITLE, title);
			 params.putString(QzoneShare.SHARE_TO_QQ_SUMMARY, summary);
			 params.putString(QzoneShare.SHARE_TO_QQ_TARGET_URL, url);
			 params.putStringArrayList(QzoneShare.SHARE_TO_QQ_IMAGE_URL, images);
			 mTencent.shareToQzone(Lightning.activity, params, new BaseUiListener());

	}
}

}
