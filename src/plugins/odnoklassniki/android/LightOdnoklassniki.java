package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.ok.android.sdk.Odnoklassniki;
import ru.ok.android.sdk.OkListener;
import ru.ok.android.sdk.util.OkScope;
import ru.redspell.lightning.Lightning;
import android.os.AsyncTask;
import java.util.Map;
import java.util.HashMap;
import org.json.JSONObject;
import org.json.JSONException;
import org.json.JSONArray;
import java.sql.Timestamp;

class LightOdnoklassniki {
	public static Odnoklassniki ok;
	public static String uid;

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

	public static void init (String appId, String appSecret, String appKey) {
		Log.d ("LIGHTNING", "odnoklassniki_init: "+appId +" " + appSecret + " " + appKey);
		ok = Odnoklassniki.createInstance(Lightning.activity, appId, appSecret, appKey );
	}

 private static String okToken = null;
	public static void authorize (final int success, final int fail, final boolean force) {
		Log.d ("LIGHTNING", "odnoklassniki_authorize");
		
		Log.d ("LIGHTNING", "force" + force);
		if (force) {
			Log.d ("LIGHTNING", "force: clear tokens");
			ok.clearTokens ();
		}


		ok.checkValidTokens (new OkListener() {
													@Override
													public void onSuccess(final JSONObject json) {
																try {

																	Log.d ("LIGHTNING", "access_token: " + (json.getString("access_token")));
																	okToken = json.getString("access_token");
																	Log.d ("LIGHTNING", "odnoklassniki_auth_success1");
																	new GetCurrentUserTask().execute(new FriendsRequest (success, fail));
																} catch (JSONException e) {
																	Log.d ("LIGHTNING", "odnoklassniki_auth_error1");
																	(new Fail (success, fail, e.toString ())).run();
																	Log.d ("LIGHTNING", "error: " + e.toString ());
																}

													}

													@Override
													public void onError(String error) {
														Log.d ("LIGHTNING", "no token");
														ok.setOkListener ( new OkListener() {
														@Override
														public void onSuccess(final JSONObject json) {
																try {

																	Log.d ("LIGHTNING", "access_token: " + (json.getString("access_token")));
																	okToken = json.getString("access_token");
																	Log.d ("LIGHTNING", "odnoklassniki_auth_success2");
																	new GetCurrentUserTask().execute(new FriendsRequest (success, fail));
																} catch (JSONException e) {
																	Log.d ("LIGHTNING", "error: " + e.toString ());
																	Log.d ("LIGHTNING", "odnoklassniki_auth_error2");
																	(new Fail (success, fail, e.toString ())).run();
																}

														}

														@Override
														public void onError(String error) {
															Log.d ("LIGHTNING", "odnoklassniki_auth_error3:" + error );
															(new Fail (success, fail, error)).run();
														}
														});
													 ok.requestAuthorization(Lightning.activity, false,OkScope.VALUABLE_ACCESS);

		}
	});
}

	public static void friends (final int success, final int fail) {
		new GetFriendsTask().execute(new FriendsRequest (success, fail));
	}
	public static void users (final int success, final int fail, final String uids) {
		if (!uids.isEmpty ()) { 
			new GetUsersInfoTask().execute (new UsersRequest (success, fail, uids));
		}
		else {
			(new FriendsSuccess(success, fail, new Friend[0])).run();
		}
	}

  public static String getOkToken () {
		return okToken;
  }
	public static String token () {
		Log.d ("LIGHTNING","token is null" + (getOkToken()==null));

		return (getOkToken () == null ? "" : getOkToken ());
	}

	public static String uid () {
		Log.d ("LIGHTNING","uid is null" + (uid==null));
		return (uid == null ? "" : uid);
	}

	public static void logout () {
		Log.d ("LIGHTNING", "OK: logout");
		ok.clearTokens ();
	}

  protected static final class GetCurrentUserTask extends AsyncTask<FriendsRequest, Void, String> {
		static int success;
		static int fail;

    @Override
    protected String doInBackground(final FriendsRequest... frequest) {
			success = frequest[0].success;
			fail = frequest[0].fail;
      try {
        return LightOdnoklassniki.ok.request("users.getCurrentUser", null, "get");
      } catch (Exception exc) {
        Log.e("Odnoklassniki", "Failed to get current user info", exc);
		//		(new Fail (success, fail, "Failed to get currrent user info")).run();
      }
      return null;
    }

    @Override
    protected void onPostExecute(final String result) {
      if (result != null) {
        Log.d("LIGHTNING", "Get user info result " + result);

				try {
					JSONObject item =new  JSONObject(result);
					uid = item.getString("uid");
					(new AuthSuccess(success, fail)).run();
				}
				catch (org.json.JSONException e) {
					(new Fail(success, fail, "Failed on parse user json")).run();
				};
      }
			else {
				(new Fail (success, fail, "Failed to get currrent user info")).run();
			}
    }
  }

	protected static final class GetFriendsTask extends AsyncTask<FriendsRequest, Void, String> {
		static int success;
		static int fail;

    @Override
    protected void onPreExecute() {
        Log.d("LIGHTNING", "Get user friends pre execute");
      }
    @Override
    protected String doInBackground(final FriendsRequest... frequest) {
			success = frequest[0].success;
			fail = frequest[0].fail;

      try {
				return LightOdnoklassniki.ok.request("friends.get", null, "get");
      } catch (Exception exc) {
        Log.d("LIGHTNING", "Failed to get friends");
				(new Fail (success, fail, "Failed to get friends")).run();

      }
      return null;
    }
    @Override
    protected void onPostExecute(final String result) { 
			if (result != null) {
        //Log.d("LIGHTNING", "Get user friends result " + result);
				LightOdnoklassniki.users (success, fail, result);
      }
    }
 }

 public static class FriendsRequest  {
	 public int success;
	 public int fail;

	 public FriendsRequest (int success, int fail) {
		 this.success = success;
		 this.fail = fail;
	 }
 }

 protected static class UsersRequest extends FriendsRequest {
	 public String uids;

	 public UsersRequest (int success, int fail, String uids) {
		 super (success, fail);
		 this.uids = uids;
	 }

 }
 protected static final class GetUsersInfoTask extends AsyncTask<UsersRequest, Void, String> {
	 private static Map params = new HashMap<String,String>() ;
	 static int success;
	 static int fail;
	 static boolean error = false;
	 

    @Override
    protected void onPreExecute() {
        Log.d("LIGHTNING", "Get users info pre execute");
      }
    @Override
    protected String doInBackground(final UsersRequest... urequest) {
			success = urequest[0].success;
			fail = urequest[0].fail;
			try {
				JSONArray uids = new JSONArray (urequest[0].uids);
				String str = new String ();
				str=uids.getString (0);
				for(int i = 1; i < uids.length(); i++){
					str+="," + uids.getString (i);
				}
				params.put("uids", str);
				params.put("fields", "uid, first_name, last_name, gender, online, last_online, pic190x190");
				try {
					return LightOdnoklassniki.ok.request("users.getInfo", params, "get");
				} catch (Exception exc) {
					Log.d("LIGHTNING", "Failed to get users");
					error = true;
					//(new Fail (success, fail, "Failed to get users")).run();
				}
		  }
			catch (org.json.JSONException e) {
				Log.d("LIGHTNING", "wrong or empty json format");
				//(new FriendsSuccess(success, fail, new Friend[0])).run();
			};

      return null;
    }
    @Override
    protected void onPostExecute(final String result) {
      if (result != null) {
        Log.d("LIGHTNING", "Get users result " + result);

				try {

          JSONArray items = new JSONArray (result);

          int cnt = items.length();
          Friend[] friends = new Friend[cnt];
          Log.d("LIGHTNING", "items " + items);
          Log.d("LIGHTNING", "cnt " + cnt);

          for (int i = 0; i < cnt; i++) {
            Log.d("LIGHTNING", "item " + i  );
            JSONObject item = items.getJSONObject(i);

						int last_online = 0;
						try {
							last_online = (int)((Timestamp.valueOf (item.getString("last_online"))).getTime ()/ 1000);
						}
						catch (IllegalArgumentException exc) {
						};
            friends[i] = new Friend(item.getString("uid"), item.getString("last_name") + " " + item.getString("first_name"), item.getString("gender").equals("female") ? 1 :item.getString("gender").equals("male") ? 2 : 0,
                          item.getString("pic190x190"), item.has("online") ? true :false, item.has("last_online") ? last_online : 0);

          }

          Log.d("LIGHTNING", "call success cnt " + cnt);
          (new FriendsSuccess(success, fail, friends)).run();
        } catch (org.json.JSONException e) {
          Log.d("LIGHTNING", "Friends onComplete Fail");
          (new Fail(success, fail, "wrong format of result on friends request")).run();
        }
      }
			else if (error) {

					(new Fail (success, fail, "Failed to get users")).run();
			}
			else {
				(new FriendsSuccess(success, fail, new Friend[0])).run();
			}
    }
 }
}
