package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;
import org.json.JSONObject;
import org.json.JSONArray;
import com.facebook.*;
import com.facebook.login.*;
import java.util.Arrays;
import android.content.Intent;
import android.os.Bundle;

class LightFacebook {
	public static CallbackManager callbackManager;

	public static void init (String appId) {
		Log.d("LIGHTNING", "init call" + FacebookSdk.isInitialized ());
		if (!FacebookSdk.isInitialized ()) {
			Log.d("LIGHTNING", "init call" + FacebookSdk.isInitialized ());
			FacebookSdk.sdkInitialize(Lightning.activity);
			Log.d("LIGHTNING", "init call" + FacebookSdk.isInitialized ());
		}
		Log.d ("LIGHTNING", "facebook_init: "+appId + "get app id: " + (FacebookSdk.getApplicationId()));
		Log.d("LIGHTNING", "init call" + FacebookSdk.isInitialized ());

		Lightning.activity.addUiLifecycleHelper(new ru.redspell.lightning.IUiLifecycleHelper() {
				public void onCreate(Bundle savedInstanceState) {}
				public void onResume() {}

				public void onActivityResult(int requestCode, int resultCode, Intent data) {
						Log.d("LIGHTNING", "facebook onActivityResult");
						callbackManager.onActivityResult(requestCode, resultCode, data);
				}

				public void onSaveInstanceState(Bundle outState) {}
				public void onPause() {}
				public void onStop() {}
				public void onDestroy() {}
		});
	}

	public static void connect(String[] perms) {
		Log.d("LIGHTNING", "connect call");

		callbackManager = CallbackManager.Factory.create();

    LoginManager.getInstance().registerCallback(callbackManager,
            new FacebookCallback<LoginResult>() {
                @Override
                public void onSuccess(LoginResult loginResult) {
                    // App code
									Log.d("LIGHTNING", "onSuccess");
                }

                @Override
                public void onCancel() {
                     // App code
									Log.d("LIGHTNING", "onCancel");
                }

                @Override
                public void onError(FacebookException exception) {

									Log.d("LIGHTNING", "onError");
                     // App code   
                }
    });
		LoginManager.getInstance().logInWithReadPermissions(Lightning.activity, Arrays.asList (perms));
			/*
			for (int i = 0; i < perms.length; i++) {
					String perm = perms[i];
					Log.d("LIGHTNING", "additional permission " + perm);

					if (PUBLISH_PERMISSIONS.contains(perm)) {
							if (publishPerms == null) publishPerms = new ArrayList();
							publishPerms.add(perm);
					} else {
							if (readPerms == null) readPerms = new ArrayList();
							readPerms.add(perm);
					}
			}

			LightFacebook.session = openActiveSession(Lightning.activity, true, sessionCallback);
			Log.d("LIGHTNING", "lightfacebook session " + (LightFacebook.session == null ? "null" : "not null"));
			*/
	}

	public static void disconnect () {
		Log.d("LIGHTNING", "disconnect call ");
		(LoginManager.getInstance ()).logOut();
	}

	public static boolean loggedIn() {
			Log.d("LIGHTNING", "loggedIn call " + FacebookSdk.isInitialized ());

			return (AccessToken.getCurrentAccessToken () != null);
	}

	public static String accessToken() {
		Log.d("LIGHTNING", "accessToken call " + FacebookSdk.isInitialized ());
		return (AccessToken.getCurrentAccessToken ()) != null ? AccessToken.getCurrentAccessToken ().getToken () : "";
	}


}

