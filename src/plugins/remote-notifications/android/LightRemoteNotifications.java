package ru.redspell.lightning.plugins;


import com.google.android.gms.gcm.GoogleCloudMessaging;
import android.content.SharedPreferences;
import ru.redspell.lightning.utils.Log;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;


import ru.redspell.lightning.LightActivity;

public class LightRemoteNotifications {

	private static final String LOG_TAG = "LIGHTNING";
	private static final String PROPERTY_APP_VERSION = "appVersion";
	private static final String PROPERTY_REG_ID = "registration_id";

	private String senderID;
	GoogleCloudMessaging gcm;
	String regid = null;

	static LightRemoteNotifications init(String sid) {
		if (!LightActivity.instance.isPlayServicesAvailable) return null;
		return new LightRemoteNotifications(sid);
	};


	public LightRemoteNotifications(String sid) {
		Context context = LightActivity.instance.getApplicationContext();
		gcm = GoogleCloudMessaging.getInstance(context);
		senderID = sid;
		regid = getRegistrationId(context);
		if (regid.isEmpty()) registerInBackground();
		else successCallback(regid);
	};

	private String getRegistrationId(Context context) {
    final SharedPreferences prefs = getGCMPreferences(context);
    String registrationId = prefs.getString(PROPERTY_REG_ID, "");
    if (registrationId.isEmpty()) {
        Log.d(LOG_TAG,"Registration not found.");
        return "";
    }
    // Check if app was updated; if so, it must clear the registration ID
    // since the existing regID is not guaranteed to work with the new
    // app version.
    int registeredVersion = prefs.getInt(PROPERTY_APP_VERSION, Integer.MIN_VALUE);
    int currentVersion = getAppVersion(context);
    if (registeredVersion != currentVersion) {
        Log.d("App version changed.");
        return "";
    }
    return registrationId;
	}

	private static int getAppVersion(Context context) {
    try {
			PackageInfo packageInfo = context.getPackageManager() .getPackageInfo(context.getPackageName(), 0);
			return packageInfo.versionCode;
    } catch (PackageManager.NameNotFoundException e) {
			throw new RuntimeException("Could not get package name: " + e);
    }
	}

	private SharedPreferences getGCMPreferences(Context context) {
    return context.getSharedPreferences(LightActivity.class.getSimpleName(), Context.MODE_PRIVATE);
	}

	private void registerInBackground() {
		Log.d("Register in background");
		LightActivity.instance.runOnUiThread(new Runnable() {
			private String err = null;
			@Override 
			public void run() {
				Log.d("Register in main thread");
				new AsyncTask<Void,Void,String>() {
						protected String doInBackground(Void... params) {
							String res;
							try {
								Log.d("RN register with " + senderID);
								res = gcm.register(senderID);
							 } catch (java.io.IOException ex) {
								 err = ex.getMessage();
								 res = null;
							 }
							return res;
						}

						@Override
						protected void onPostExecute(final String res) {
							Log.d("RN onPostExecute");
							LightActivity lightActivity = LightActivity.instance;
							Runnable r;
							if (res == null) 
								r = new Runnable() {
									@Override 
									public void run() {
										errorCallback(err);
									}
								};
							else {
								storeRegistrationId(lightActivity.getApplicationContext(),res);
								r = new Runnable() {
									@Override 
									public void run() {
										successCallback(res);
									}
								};
							};
							// Store here, and post to ocaml
							lightActivity.lightView.queueEvent(r);
						}
				}.execute(null, null, null);
			}
		});
	};

	private void storeRegistrationId(Context context, String regId) {
		final SharedPreferences prefs = getGCMPreferences(context);
		int appVersion = getAppVersion(context);
		Log.d("Saving regId on app version " + appVersion);
		SharedPreferences.Editor editor = prefs.edit();
		editor.putString(PROPERTY_REG_ID, regId);
		editor.putInt(PROPERTY_APP_VERSION, appVersion);
		editor.commit();
	}


	native private void errorCallback(String err);
	native private void successCallback(String regid);


}
