package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;
import org.json.JSONObject;
import org.json.JSONArray;
import com.facebook.*;
import com.facebook.login.*;
import com.facebook.share.*;
import com.facebook.share.model.*;
import com.facebook.share.widget.*;
import java.util.List;
import android.content.Intent;
import android.os.Bundle;
import java.util.ArrayList;
import java.util.Set;
import java.lang.Runnable;
import android.net.Uri;
import org.json.JSONException;
import com.facebook.internal.Utility;

class LightFacebook {
	public static CallbackManager callbackManager;

	public static void init (String appId) {
		if (!FacebookSdk.isInitialized ()) {
			FacebookSdk.sdkInitialize(Lightning.activity);
		}
		
		Log.d ("LIGHTNING", "facebook_init: "+appId + " get app id: " + (FacebookSdk.getApplicationId()) + " profile is " + ((Profile.getCurrentProfile ()) != null) + " token is " + ((AccessToken.getCurrentAccessToken ()) != null)) ;

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

	private static ArrayList readPerms = null;
	private static ArrayList publishPerms = null;

	private static final int EXTRA_PERMS_NOT_REQUESTED = 0;
	private static final int READ_PERMS_REQUESTED = 1;
	private static final int PUBLISH_PERMS_REQUESTED = 2;

	private static int extraPermsState = EXTRA_PERMS_NOT_REQUESTED;

	private static final int COMMON_GRAPHREQUEST= 0;
	private static final int FRIENDS_GRAPHREQUEST = 1;
	private static final int USERS_GRAPHREQUEST = 2;

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

	private static class FriendsCallback implements Runnable {
		  protected Friend[] friends;
			protected int success;
			protected int fail;

			public FriendsCallback (int success, int fail, Friend[] friends) {
					this.friends = friends;
					this.success= success;
					this.fail= fail;
			}

			public native void nativeRun(int success, int fail, Friend[] friends);

			public void run() {
				nativeRun(success, fail, friends);
			}
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

		if (AccessToken.getCurrentAccessToken () != null) {
			// need profile information right now
			if (Profile.getCurrentProfile () != null) {
			Lightning.activity.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						Log.d("LIGHTNING", "run ");
						GraphRequest.Callback graphCallback = new GraphRequest.Callback() {
										@Override
										public void onCompleted(GraphResponse response) {
												if (response.getError() != null) {
														LoginManager.getInstance().logInWithReadPermissions(Lightning.activity, readPerms);
												} else {
													JSONObject userInfo = response.getJSONObject();

																String id = userInfo.optString("id");
																if (id == null) {
																	Log.d("LIGHTNING", "no id");
																}
																String link = userInfo.optString("link");
																Profile profile = new Profile(
																				id,
																				userInfo.optString("first_name"),
																				userInfo.optString("middle_name"),
																				userInfo.optString("last_name"),
																				userInfo.optString("name"),
																				link != null ? Uri.parse(link) : null
																);
																Profile.setCurrentProfile(profile);
																(new CamlCallback("fb_success")).run();
												}
										}
								};

						Bundle parameters = new Bundle();
						parameters.putString("fields", "id,name,first_name,middle_name,last_name,link");
						parameters.putString("access_token", AccessToken.getCurrentAccessToken ().getToken ());
							GraphRequest graphRequest = new GraphRequest(
									null,
									"me",
									parameters,
									HttpMethod.GET,
									null);

						graphRequest.setCallback(graphCallback);
						graphRequest.executeAsync();
					}
			});
			}
		}
		else {
			(new CamlParamCallback("fb_fail", "empty access token")).run();
		}
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

	public static String uid () {
		Log.d("LIGHTNING", "accessToken call");
		return (Profile.getCurrentProfile ()) != null ? Profile.getCurrentProfile ().getId () : "";
	}

	private static void _graphrequest(final String[] paths, final Bundle params, final int successCallback, final int failCallback, final int httpMethod, final int handlerType) {
			Lightning.activity.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						List<GraphRequest> requests = new ArrayList<GraphRequest>();
						final List<GraphResponse> results = new ArrayList<GraphResponse>();
						final GraphRequestBatch batch;
						for (final String path: paths) {
							Log.d("LIGHTNING", "p" + path);
							requests.add (
								new GraphRequest(AccessToken.getCurrentAccessToken (), path, params, httpMethod == 0 ? com.facebook.HttpMethod.GET : com.facebook.HttpMethod.POST, new com.facebook.GraphRequest.Callback () {
											@Override
											public void onCompleted(GraphResponse response) {
													Log.d("LIGHTNING", "graphrequest onCompleted" + response);

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
																									/*TODO:
																									switch (handlerType) {
																										case COMMON_GRAPHREQUEST: {
																															(new GraphResponseHandler (response, successCallback, failCallback)).run ();
																															break;
																										}
																										case FRIENDS_GRAPHREQUEST: {
																															(new GraphResponseFriendsHandler (response, successCallback, failCallback)).run ();
																															break;
																										}
																										case USERS_GRAPHREQUEST: {
																															(new GraphResponseUsersHandler (response, successCallback, failCallback)).run ();
																															break;
																										}
																									}
																									*/
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
																Log.d ("LIGHTNING", "Unresolvable ERROR");
																/*
																batch.clear ();
																(new CamlParamCallbackInt(failCallback, error.getErrorMessage())).run();
																(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
																*/
															}
													} else {
														results.add (response);
														/*
																switch (handlerType) {
																	case COMMON_GRAPHREQUEST: {
																						(new GraphResponseHandler (response,successCallback, failCallback)).run ();
																						break;
																	}
																	case FRIENDS_GRAPHREQUEST: {
																						(new GraphResponseFriendsHandler (response,successCallback, failCallback)).run ();
																						break;
																	}
																	case USERS_GRAPHREQUEST: {
																						(new GraphResponseUsersHandler (response,successCallback, failCallback)).run ();
																						break;
																	}
																}
																*/
													}
											}

								}
			));

						}
						batch = new GraphRequestBatch (requests);
						batch.addCallback(new GraphRequestBatch.Callback() {
							    @Override
							    public void onBatchCompleted(GraphRequestBatch graphRequests) {
										        // Application code for when the batch finishes
											Log.d("LIGHTNING", "batch onCompleted");
											switch (handlerType) {
												case COMMON_GRAPHREQUEST: {
																	(new GraphResponseHandler (results,successCallback, failCallback)).run ();
																	break;
												}
												case FRIENDS_GRAPHREQUEST: {
																	(new GraphResponseFriendsHandler (results,successCallback, failCallback)).run ();
																	break;
												}
												case USERS_GRAPHREQUEST: {
																	(new GraphResponseFriendsHandler (results,successCallback, failCallback)).run ();
																	break;
												}
											}
									}
						});
						batch.executeAsync();

					}
			});

	}

	public static void share(String text, String link, String picUrl, final int success, final int fail) {
		ShareLinkContent.Builder builder = new ShareLinkContent.Builder();
		builder.setContentTitle (text);
		builder.setImageUrl (Uri.parse(picUrl));
		builder.setContentUrl(Uri.parse (link));
		ShareLinkContent content = builder.build();
		ShareDialog shareDialog;
		shareDialog = new ShareDialog(Lightning.activity);
		if (callbackManager == null) {
			callbackManager = CallbackManager.Factory.create();
		}
		shareDialog.registerCallback(callbackManager, 
            new FacebookCallback<Sharer.Result>() {
                @Override
                public void onSuccess(Sharer.Result result) {
									Log.d("LIGHTNING", "share onSuccess");
									(new CamlCallbackInt(success)).run();
									(new ReleaseCamlCallbacks(success, fail)).run();
                }

                @Override
                public void onCancel() {
									Log.d("LIGHTNING", "share nCancel");
									(new CamlParamCallbackInt(fail, "share cancel")).run();
									(new ReleaseCamlCallbacks(success, fail)).run();
                }

                @Override
                public void onError(FacebookException exception) {
									Log.d("LIGHTNING", "share onError " + exception.toString ());
									(new CamlParamCallbackInt(fail, exception.toString())).run ();
									(new ReleaseCamlCallbacks(success, fail)).run();
                }
		});

		ShareDialog.show(Lightning.activity,content);
	}

	public static void graphrequest(final String path, final Bundle params, final int successCallback, final int failCallback, final int httpMethod) {
		String[] paths = {path}; 
		_graphrequest(paths,params,successCallback,failCallback,httpMethod, COMMON_GRAPHREQUEST);
	}

	public static void friends (final int success, final int fail) {
		String[] paths = {"me/friends"}; 
		Bundle params = new Bundle ();
		params.putString ("fields","gender,id,name,picture"); 
		_graphrequest(paths,params,success,fail,0, FRIENDS_GRAPHREQUEST);
	}

	public static void users (final int success, final int fail, final String uids) {
		String[] paths = uids.split (",");
		for (String p:paths) {
			Log.d ("path "+ p);
		}
		Bundle params = new Bundle ();
		params.putString ("fields","gender,id,name,picture"); 

		_graphrequest(paths,params,success,fail,0, USERS_GRAPHREQUEST);
	}

	private static class GraphResponseHandler implements Runnable {
			protected List<GraphResponse> responses;
			protected int successCallback;
			protected int failCallback;

			public GraphResponseHandler (List<GraphResponse> responses, int success, int fail) {
					this.responses = responses;
					this.successCallback = success;
					this.failCallback = fail;
			}

			@Override
			public void run() {
				String json = null;

				GraphResponse response = responses.get(0);
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

	private static class GraphResponseFriendsHandler extends GraphResponseHandler {

			public GraphResponseFriendsHandler (List<GraphResponse> responses, int success, int fail) {
				super(responses,success,fail);
			}

			@Override
			public void run() {
				JSONArray jsonArray = null;
				for (GraphResponse r:responses) {
				Log.d("LIGHTNING", "response" + r);
				}
				if (responses.size() ==1) {

					GraphResponse response = responses.get(0);
					if (response.getJSONObject() != null) {
						try {
							if (response.getJSONObject().getJSONArray("data") != null) {
								jsonArray = response.getJSONObject().getJSONArray("data");
							}
							else {
								Log.d("LIGHTNING", "no array");
								for (GraphResponse r:responses) {
									if (r.getJSONObject() != null) {
										jsonArray.put(r.getJSONObject());
									}
								}}
						}
						catch (JSONException exc) {
						}
					} else if (response.getJSONArray() != null) {
							jsonArray = response.getJSONArray();
					}
				}
				else {
					jsonArray = new JSONArray();
					for (GraphResponse r:responses) {
						if (r.getJSONObject() != null) {
							jsonArray.put(r.getJSONObject());
						}
					}
				}

				Log.d("LIGHTNING", "json " + jsonArray.toString());


				if (jsonArray == null) {
					(new CamlParamCallbackInt(failCallback, "something wrong with graphrequest response (not json object, not json objects list)")).run();
					(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
				} else {

					try {
						int cnt = jsonArray.length();
						Friend[] friends = new Friend[cnt];
						Log.d("LIGHTNING", "json " + jsonArray.toString());
						Log.d("LIGHTNING", "cnt " + cnt);

						for (int i = 0; i < cnt; i++) {
							JSONObject item = jsonArray.getJSONObject(i);
							Log.d("LIGHTNING", "item " + i +": " + item  );
							JSONObject pic = (item.getJSONObject ("picture")).getJSONObject ("data");

							friends[i] = new Friend(item.getString("id"), item.getString("name"), item.optString("gender").equals("female") ? 1 :item.optString("gender").equals("male") ? 2 : 0,
														pic.getString("url"), false, 0);

						}
						(new FriendsCallback (successCallback, failCallback, friends)).run();
					} catch (org.json.JSONException e) {
						Log.d("LIGHTNING", "Friends onComplete Fail");
						(new CamlParamCallbackInt(failCallback, "something wrong with graphrequest response (not json object, not json objects list)")).run();
						(new ReleaseCamlCallbacks(successCallback, failCallback)).run();
					}
				}

			}
	}

	/*
	private static class GraphResponseUsersHandler extends GraphResponseHandler {

			public GraphResponseUsersHandler (List responses, int success, int fail) {
				super(response,success,fail);
			}

			@Override
			public void run() {
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
	*/
}

