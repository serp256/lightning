package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.ok.android.sdk.Odnoklassniki;
import ru.ok.android.sdk.OkTokenRequestListener;
import ru.ok.android.sdk.util.OkScope;
import ru.redspell.lightning.Lightning;
import android.os.AsyncTask;

class LightOdnoklassniki {
	public static Odnoklassniki ok;

  private static abstract class Callback implements Runnable {
		protected int success;
		protected int fail;

		public abstract void run();

		public Callback(int success, int fail) {
			this.success = success;
			this.fail = fail;
		}
	}

/*
	private static class AuthSuccess extends Callback {
		public AuthSuccess(int success, int fail) {
			super(success, fail);
		}

		public native void nativeRun(int success, int fail);

		public void run() {
			nativeRun(success, fail);
		}
	}
*/
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

/*
    public native void nativeRun(int success, int fail, Friend[] friends);

    public void run() {
      nativeRun(success, fail, friends);
    }
  }
*/
	public static void init (String appId, String appSecret, String appKey) {
		Log.d ("LIGHTNING", "odnoklassniki_init: "+appId +" " + appSecret + " " + appKey);
		
		ok = Odnoklassniki.createInstance(Lightning.activity, appId, appSecret, appKey);
	}

	public static void authorize (final int success, final int fail) {
		Log.d ("LIGHTNING", "odnoklassniki_authorize");
		
		ok.setTokenRequestListener(new OkTokenRequestListener() {
			@Override
			public void onSuccess(final String accessToken) {
				/*Toast.makeText(mContext, "Recieved token : " + accessToken, Toast.LENGTH_SHORT).show();
				showForm();
				*/

				Log.d ("LIGHTNING", "odnoklassniki_auth_success");
/*
				(new AuthSuccess(success, fail)).run();

				new GetFriendsTask().execute(new Void[0]);
*/
				new GetFriendsTask().execute(new Void[0]);

			}

		@Override
			public void onCancel() {
				/*
				Toast.makeText(mContext, "Authorization was canceled", Toast.LENGTH_SHORT).show();
				*/
				Log.d ("LIGHTNING", "odnoklassniki_auth_cancel");
/*
				(new AuthSuccess(success, fail)).run();
*/
			}

		@Override
			public void onError() {
				Log.d ("LIGHTNING", "odnoklassniki_auth_error");
				/*
				(new AuthSuccess(success, fail)).run();
				Toast.makeText(mContext, "Error getting token", Toast.LENGTH_SHORT).show();
				*/
			}
		});

		if (ok.hasAccessToken()) {
				Log.d ("LIGHTNING", "odnoklassniki_auth_has_token");
		}
		else
		{
				ok.requestAuthorization(Lightning.activity, false, OkScope.VALUABLE_ACCESS);
		}
	}

  protected static final class GetFriendsTask extends AsyncTask<Void, Void, String> {

    @Override
    protected void onPreExecute() {
        Log.d("LIGHTNING", "Get user friends pre execute");
      }
    }
    @Override
    protected String doInBackground(final Void... params) {
			Log.d("LIGHTNING", "do in background");
      try {
        return LightOdnoklassniki.ok.request("friends.get", null, "get");
      } catch (Exception exc) {
        Log.d("LIGHTNING", "Failed to get friends");
      }
      return null;
    }

    @Override
    protected void onPostExecute(final String result) {
      if (result != null) {
        Log.d("LIGHTNING", "Get user friends result");
      }
    }
  }
}
