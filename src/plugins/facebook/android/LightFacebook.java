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
import java.util.ArrayList;
import java.util.Set;
import java.lang.Runnable;

class LightFacebook {
	public static CallbackManager callbackManager;

	public static void init (String appId) {
		if (!FacebookSdk.isInitialized ()) {
			FacebookSdk.sdkInitialize(Lightning.activity);
		}
		
		Log.d ("LIGHTNING", "facebook_init: "+appId + "get app id: " + (FacebookSdk.getApplicationId()));

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

	private static ArrayList readPerms = null;
	private static ArrayList publishPerms = null;

	private static final int EXTRA_PERMS_NOT_REQUESTED = 0;
	private static final int READ_PERMS_REQUESTED = 1;
	private static final int PUBLISH_PERMS_REQUESTED = 2;

	private static int extraPermsState = EXTRA_PERMS_NOT_REQUESTED;

	private static String[] PUBLISH_PERMISSIONS_ARR = {
			"publish_actions",
			"ads_management",
			"create_event",
			"rsvp_event",
			"manage_friendlists",
			"manage_notifications",
			"manage_pages"
	};

	private static ArrayList<String> PUBLISH_PERMISSIONS = new ArrayList<String>(java.util.Arrays.asList(PUBLISH_PERMISSIONS_ARR));

	private static void fbLoginWithPublishPermissions () {
		Log.d("LIGHTNING", "fbLoginWithPublishPermissions");
		extraPermsState = PUBLISH_PERMS_REQUESTED;
		LoginManager.getInstance().logInWithPublishPermissions(Lightning.activity, publishPerms);
	}

	private static void fbLoginWithReadPermissions () {
		Log.d("LIGHTNING", "fbLoginWithReadPermissions");
		extraPermsState = READ_PERMS_REQUESTED;
		LoginManager.getInstance().logInWithReadPermissions(Lightning.activity, readPerms);
	}

	private static void checkPermissions (final Runnable success, final Runnable fail) {
        Log.d("LIGHTNING", "checkPermissions state " + extraPermsState );
				if (AccessToken.getCurrentAccessToken () != null) {

					AccessToken accessToken;
					accessToken = AccessToken.getCurrentAccessToken ();
					boolean readPermissionsChecked = true;
					boolean publishPermissionsChecked = true;

						if (accessToken.getPermissions () != null) {
							Set grantedPermissions = accessToken.getPermissions ();

								switch (extraPermsState) {
										case READ_PERMS_REQUESTED:
												if (readPerms != null && readPerms.size() > 0) {
													Log.d("LIGHTNING", "check1");
													for(int i=0; i < readPerms.size (); i++){
														if (!grantedPermissions.contains(readPerms.get(i))) {
															readPermissionsChecked = false;
															break;
														}
													}
												}
												if (readPermissionsChecked) {
													Log.d("LIGHTNING", "check2");
													if (publishPerms != null && publishPerms.size() > 0) {
														for(int i=0; i < publishPerms.size (); i++){
															if (!grantedPermissions.contains(publishPerms.get(i))) {
																publishPermissionsChecked = false;
																fbLoginWithPublishPermissions ();
																break;
															}
														}
													}
													if (publishPermissionsChecked) {
														Log.d("LIGHTNING", "check3");
														extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
														if (success == null) {
															connectSuccess ();
														}
														else {
															Lightning.activity.runOnUiThread(success);
														}
													}
							          }
												else {
													extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
													if (fail== null) {
														fbError("Permissions check failed");
													}
													else {
														Lightning.activity.runOnUiThread(fail);
													}
												}
												break;

										case PUBLISH_PERMS_REQUESTED:
												if (publishPerms != null && publishPerms.size() > 0) {
													Log.d("LIGHTNING", "check4");
													for(int i=0; i < publishPerms.size (); i++){
														if (!grantedPermissions.contains(publishPerms.get(i))) {
															publishPermissionsChecked = false;
															break;
														}
													}
												}
												extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
												if (publishPermissionsChecked) {
													if (success == null) {
														connectSuccess ();
													}
													else {
														Lightning.activity.runOnUiThread(success);
													}
												}
												else {
													if (fail== null) {
														fbError("Permissions check failed");
													}
													else {
														Lightning.activity.runOnUiThread(fail);
													}
												}
												break;

										case EXTRA_PERMS_NOT_REQUESTED:
												if (readPerms != null && readPerms.size() > 0) {
													for(int i=0; i < readPerms.size (); i++){
														 if (!grantedPermissions.contains(readPerms.get(i))) {
															readPermissionsChecked = false;
															fbLoginWithReadPermissions ();
															break;
														}
													}
												}
												if (readPermissionsChecked) {
													extraPermsState = READ_PERMS_REQUESTED;
													checkPermissions (success, fail);
							          }
												break;
								}
						}
						else
							//empty granted permissions
							if (readPerms == null && publishPerms == null) {
								if (success == null) {
									connectSuccess ();
								}
								else {
									Lightning.activity.runOnUiThread(success);
								}

							}
							else {
								if (fail== null) {
									fbError("Permissions check failed: no granted permissions");
								}
								else {
									Lightning.activity.runOnUiThread(fail);
								}
							}
				}
				else 
					//no token
					if (fail == null) {
						fbError("Permissions check failed: not authorized");
					}
					else {
						Lightning.activity.runOnUiThread(fail);
					}
	}

	private static class CamlCallback implements Runnable {
			protected String name;

			public CamlCallback (String name) {
					this.name = name;
			}

			@Override
			public native void run();
	}

	private static class CamlParamCallback extends CamlCallback {
			protected String param;

			public CamlParamCallback (String name, String param) {
					super(name);
					this.param = param;
			}

			@Override
			public native void run();
	}

	private static class CamlCallbackInt implements Runnable {
			protected int callback;

			public CamlCallbackInt (int callback) {
					this.callback= callback;
			}

			@Override
			public native void run();
	}

	private static class CamlParamCallbackInt extends CamlCallbackInt {
			protected String param;

			public CamlParamCallbackInt (int callback, String param) {
					super(callback);
					this.param = param;
			}

			@Override
			public native void run();
	}

	private static class ReleaseCamlCallbacks implements Runnable {
			protected int successCallback;
			protected int failCallback;

			public ReleaseCamlCallbacks(int successCallback, int failCallback) {
					this.successCallback = successCallback;
					this.failCallback = failCallback;
			}

			@Override
			public native void run();
	}

	private static void connectSuccess() {
		Log.d("LIGHTNING", "connect success");
		(new CamlCallback("fb_success")).run();
	}

	private static void fbError(String mes) {
		Log.d("LIGHTNING", "connect fail");
		(new CamlParamCallback("fb_fail", mes)).run();
	}

	private static void parsePermissions (String[] perms) {
		if (readPerms !=null) {
			readPerms.clear();
			readPerms = null;
		}
		if (publishPerms != null) {
			publishPerms.clear();
			publishPerms = null;
		}

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
	}

	public static void connect(String[] perms) {
		Log.d("LIGHTNING", "connect call");

		callbackManager = CallbackManager.Factory.create();

    LoginManager.getInstance().registerCallback(callbackManager,
            new FacebookCallback<LoginResult>() {
                @Override
                public void onSuccess(LoginResult loginResult) {
									Log.d("LIGHTNING", "onSuccess");
									checkPermissions (null, null);
                }

                @Override
                public void onCancel() {
									Log.d("LIGHTNING", "onCancel");
									fbError("FB Authorization cancelled");
                }

                @Override
                public void onError(FacebookException exception) {
									Log.d("LIGHTNING", "onError");
									fbError(exception.getMessage ());
                }
    });

		parsePermissions (perms);

		if (loggedIn ()) {
			Log.d("LIGHTNING", "already authorized");
			checkPermissions (null, null);
		}
		else {
			Log.d("LIGHTNING", "try authorize");
			LoginManager.getInstance().logInWithReadPermissions(Lightning.activity, readPerms);
		}
	}

	private static void reconnect (final Runnable success,final Runnable fail) {
		Log.d("LIGHTNING", "reconnect call");

		if (callbackManager == null) {
			callbackManager = CallbackManager.Factory.create();
		}

    LoginManager.getInstance().registerCallback(callbackManager,
            new FacebookCallback<LoginResult>() {
                @Override
                public void onSuccess(LoginResult loginResult) {
									Log.d("LIGHTNING", "reconnect onSuccess");
									checkPermissions (success, fail);
                }

                @Override
                public void onCancel() {
									Log.d("LIGHTNING", "reconnect onCancel");
									Lightning.activity.runOnUiThread(fail);
                }

                @Override
                public void onError(FacebookException exception) {
									Log.d("LIGHTNING", "reconnect onError");
									Lightning.activity.runOnUiThread(fail);
                }
    });

		LoginManager.getInstance().logInWithReadPermissions(Lightning.activity, readPerms);
	}

	public static void disconnect () {
		Log.d("LIGHTNING", "disconnect call ");
		(LoginManager.getInstance ()).logOut();
	}

	public static boolean loggedIn() {
		Log.d("LIGHTNING", "loggedIn call");
		return (AccessToken.getCurrentAccessToken () != null);
	}

	public static String accessToken() {
		Log.d("LIGHTNING", "accessToken call");
		return (AccessToken.getCurrentAccessToken ()) != null ? AccessToken.getCurrentAccessToken ().getToken () : "";
	}

	public static void graphrequest(final String path, final Bundle params, final int successCallback, final int failCallback, final int httpMethod) {
			Lightning.activity.runOnUiThread(new Runnable() {
					@Override
					public void run() {

						new GraphRequest(AccessToken.getCurrentAccessToken (), path, params, httpMethod == 0 ? com.facebook.HttpMethod.GET : com.facebook.HttpMethod.POST, new com.facebook.GraphRequest.Callback () {
									@Override
									public void onCompleted(GraphResponse response) {
											Log.d("LIGHTNING", "graphrequest onCompleted");

											FacebookRequestError error = response.getError();

											if (error != null) {
													Log.d("LIGHTNING", "error: " + error);
													if (error.getRequestStatusCode() == 400) {
														//token is not valid; should reauth
														Runnable graphRequestRunnable = new Runnable() {
																@Override
																public void run() {

																	new GraphRequest(AccessToken.getCurrentAccessToken (), path, params, httpMethod == 0 ? com.facebook.HttpMethod.GET : com.facebook.HttpMethod.POST, new com.facebook.GraphRequest.Callback () {
																				@Override
																				public void onCompleted(GraphResponse response) {
																						Log.d("LIGHTNING", "graphrequest onCompleted");

																						FacebookRequestError error = response.getError();

																						if (error != null) {
																								Log.d("LIGHTNING", "error: " + error);
																								(new CamlParamCallbackInt(failCallback, error.getErrorMessage())).run();
																								(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
																						} else {
																								String json = null;

																								if (response.getJSONObject() != null) {
																										json = response.getJSONObject().toString();
																								} else if (response.getJSONArray() != null) {
																										json = response.getJSONArray().toString();
																								}

																								Log.d("LIGHTNING", "json " + json);

																								if (json == null) {
																									(new CamlParamCallbackInt(failCallback, "something wrong with graphrequest response (not json object, not json objects list)")).run();
																								} else {
																									(new CamlParamCallbackInt(successCallback, json)).run();
																								}

																								(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
																						}
																				}

																}).executeAsync ();
																}
														};
													  Runnable failRunnable = new Runnable() {
															@Override
																public void run () {
																	(new CamlParamCallbackInt(failCallback, "fail graphrequest cause reconnect error")).run();
																	(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
																}
													  };

														reconnect (graphRequestRunnable, failRunnable);
													}
													else {
														(new CamlParamCallbackInt(failCallback, error.getErrorMessage())).run();
													}
											} else {
													String json = null;

													if (response.getJSONObject() != null) {
															json = response.getJSONObject().toString();
													} else if (response.getJSONArray() != null) {
															json = response.getJSONArray().toString();
													}

													Log.d("LIGHTNING", "json " + json);

													if (json == null) {
														(new CamlParamCallbackInt(failCallback, "something wrong with graphrequest response (not json object, not json objects list)")).run();
													} else {
														(new CamlParamCallbackInt(successCallback, json)).run();
													}

													(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
											}
									}

						}).executeAsync ();
					}
			});

	}

}

