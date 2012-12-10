package ru.redspell.lightning;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import ru.redspell.lightning.utils.Log;
import android.view.WindowManager;
import android.view.Window;
import android.os.Messenger;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.widget.FrameLayout;
import android.content.Context;

import com.google.android.vending.expansion.downloader.DownloadProgressInfo;
import com.google.android.vending.expansion.downloader.DownloaderClientMarshaller;
import com.google.android.vending.expansion.downloader.DownloaderServiceMarshaller;
import com.google.android.vending.expansion.downloader.IDownloaderClient;
import com.google.android.vending.expansion.downloader.IStub;
import com.google.android.vending.expansion.downloader.IDownloaderService;

import ru.redspell.lightning.expansions.LightExpansionsDownloadService;
import ru.redspell.lightning.expansions.XAPKFile;
import ru.redspell.lightning.LightView;
import android.content.res.TypedArray;

import ru.redspell.lightning.payments.Security;

import android.widget.AbsoluteLayout;
import android.widget.EditText;
import android.view.View;
import android.widget.AbsoluteLayout;
import android.view.ViewGroup.LayoutParams;
import android.content.res.Configuration;

import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import java.util.ArrayList;

import android.content.SharedPreferences;

public class LightActivity extends Activity implements IDownloaderClient
{
    protected XAPKFile[] xAPKS = {};

    public XAPKFile[] getXAPKS() {
    	return xAPKS;
    }

	private final String LOG_TAG = "LIGHTNING";

	private LightView lightView;
	private IStub mDownloaderClientStub;
	private IDownloaderService mRemoteService;

	public AbsoluteLayout viewGrp;
	public static boolean isRunning = false;

	public static void addNotification(Context context, String notifId, double fireDate, String message) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences("notifications", Context.MODE_PRIVATE);

			JSONObject jsonNotif = new JSONObject()
				.put("id", notifId)
				.put("fd", fireDate)
				.put("mes", message);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString("notifications", "[]"))
				.put(jsonNotif);

			Log.d("LIGHTNING", "jsonNotifs.toString(): " + jsonNotifs.toString());
			notifSharedPrefs.edit().putString("notifications", jsonNotifs.toString()).commit();
		} catch (org.json.JSONException e) {
			Log.d("LIGHTNING", "addNotification json error");
		}
	}

	private interface NotificationComparer {
		public boolean equal(JSONObject jsonObj, String notifId, double fireDate, String message) throws JSONException;
	}

	public static void removeNotification(Context context, String notifId) {
		removeNotification(context, notifId, 0, "", new NotificationComparer() {
			public boolean equal(JSONObject jsonObj, String notifId, double fireDate, String message) throws JSONException {
				return jsonObj.getString("id").contentEquals(notifId);
			}
		});
	}

	public static void removeNotification(Context context, String notifId, double fireDate, String message) {
		removeNotification(context, notifId, fireDate, message, new NotificationComparer() {
			public boolean equal(JSONObject jsonObj, String notifId, double fireDate, String message) throws JSONException {
				return jsonObj.getString("id").contentEquals(notifId) && jsonObj.getDouble("fd") == fireDate && jsonObj.getString("mes").contentEquals(message);
			}
		});
	}	

	public static void removeNotification(Context context, String notifId, double fireDate, String message, NotificationComparer comparer) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences("notifications", Context.MODE_PRIVATE);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString("notifications", "[]"));
			ArrayList<JSONObject> notifs = new ArrayList<JSONObject>();

			for (int i = 0; i < jsonNotifs.length(); i++) {
				JSONObject jsonNotif = jsonNotifs.getJSONObject(i);

				if (!comparer.equal(jsonNotif, notifId, fireDate, message)) {
					notifs.add(jsonNotif);
				}
			}

			notifSharedPrefs.edit().putString("notifications", new JSONArray(notifs).toString()).commit();
			Log.d("LIGHTNING", "new JSONArray(notifs).toString() " + new JSONArray(notifs).toString());
		} catch (JSONException e) {
			Log.d("LIGHTNING", "removeNotification json error");
		}		
	}

	public static void rescheduleNotifications(Context context) {
		try {
			SharedPreferences notifSharedPrefs = context.getSharedPreferences("notifications", Context.MODE_PRIVATE);

			JSONArray jsonNotifs = new JSONArray(notifSharedPrefs.getString("notifications", "[]"));
			ArrayList<JSONObject> notifs = new ArrayList<JSONObject>();
			Double now = (double)java.util.Calendar.getInstance().getTimeInMillis();

			for (int i = 0; i < jsonNotifs.length(); i++) {
				JSONObject jsonNotif = jsonNotifs.getJSONObject(i);
				Double fireDate = jsonNotif.getDouble("fd");

				Log.d("LIGHTNING", jsonNotif.getString("id") + " " + new Double(fireDate).toString() + " " + new Double(now).toString() + " " + new Boolean(fireDate > now).toString());

				if (fireDate > now) {
					Log.d("LIGHTNING", "rescheduling");
					LightNotifications.scheduleNotification(context, jsonNotif.getString("id"), fireDate, jsonNotif.getString("mes"));
					notifs.add(jsonNotif);
				}
			}

			Log.d("LIGHTNING", new JSONArray(notifs).toString());
			notifSharedPrefs.edit().putString("notifications", new JSONArray(notifs).toString()).commit();			
		} catch (org.json.JSONException e) {
			Log.d("LIGHTNING", "rescheduleNotifications json error ");
		}
	}

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		// rescheduleNotifications(this);

		// savedState = savedInstanceState != null ? savedInstanceState : new Bundle();
		Log.d("LIGHTNING", "savedState " + (savedInstanceState != null));

/*		if (savedState != null) {
			ArrayList<Bundle> notifs = savedState.getParcelableArrayList(SAVED_STATE_NOTIFS_KEY);
			
			if (notifs == null) {
				Log.d("LIGHTNING", "notifs null");
			} else {
				Iterator<Bundle> iter = notifs.iterator();

				while (iter.hasNext()) {
					Bundle notifBundle = iter.next();

					Log.d("LIGHTNING", notifBundle.getString(LightNotifications.NOTIFICATION_ID_KEY));
					Log.d("LIGHTNING", new Double((notifBundle.getDouble(LightNotifications.NOTIFICATION_FIREDATE_KEY))).toString());
					Log.d("LIGHTNING", notifBundle.getString(LightNotifications.NOTIFICATION_MESSAGE_KEY));
				}
			}
		}*/
		
		super.onCreate(savedInstanceState);

		getSystemService(Context.CLIPBOARD_SERVICE);

		//setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);

		viewGrp = new AbsoluteLayout(this);		
		viewGrp.addView(lightView = new LightView(this));
		setContentView(viewGrp);

		TypedArray expansions = getResources().obtainTypedArray(R.array.expansions);
		xAPKS = new XAPKFile[expansions.length()];

		for (int i = 0; i < expansions.length(); i++) {
			String[] expFileParams = expansions.getString(i).split(",");
			xAPKS[i] = new XAPKFile((new Boolean(expFileParams[0])).booleanValue(), (new Integer(expFileParams[1])).intValue(), (new Long(expFileParams[2])).longValue());	
		}
	}

	public boolean startExpansionDownloadService() {
		Log.d(LOG_TAG, "startExpansionDownloadService call");

		Intent notifierIntent = new Intent(this, this.getClass());
		notifierIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

		PendingIntent pendingIntent = PendingIntent.getActivity(LightActivity.this, 0, notifierIntent, PendingIntent.FLAG_UPDATE_CURRENT);

		// Start the download service (if required)
		int startResult = 0;
		try {
			startResult = DownloaderClientMarshaller.startDownloadServiceIfRequired(this, pendingIntent, LightExpansionsDownloadService.class);
		} catch (PackageManager.NameNotFoundException e) {
			e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
		}

		// If download has started, initialize this activity to show download progress
		boolean retval = startResult != DownloaderClientMarshaller.NO_DOWNLOAD_REQUIRED;

		Log.d(LOG_TAG, "startResult " + startResult);
		Log.d(LOG_TAG, "retval " + retval);

		if (retval) {
			mDownloaderClientStub = DownloaderClientMarshaller.CreateStub(this, LightExpansionsDownloadService.class);
			mDownloaderClientStub.connect(this);
		}

		return retval;
	}

	public void onServiceConnected(Messenger m) {
		Log.d(LOG_TAG, "onServiceConnected call");

        mRemoteService = DownloaderServiceMarshaller.CreateProxy(m);
        mRemoteService.onClientUpdated(mDownloaderClientStub.getMessenger());		
	}

	public void onDownloadStateChanged(int newState) {
		Log.d(LOG_TAG, "onDownloadStateChanged call");

		if (newState == IDownloaderClient.STATE_COMPLETED) {
			lightView.expansionsDownloaded();
		}
	}

	public void onDownloadProgress(DownloadProgressInfo progress) {
		Log.d(LOG_TAG, "onDownloadProgress call");
	}

    @Override
    protected void onStart() {
    	isRunning = true;
        if (null != mDownloaderClientStub) {
            mDownloaderClientStub.connect(this);
        }
        super.onStart();
    }

	@Override
	protected void onPause() {
		isRunning = false;
		super.onPause();
		lightView.onPause();
	}

	@Override
	protected void onResume() {
		isRunning = true;
		super.onResume();
		lightView.onResume();

		if (null != mDownloaderClientStub) {
			mDownloaderClientStub.connect(this);
		}		
	}

	@Override
	protected void onStop() {
		isRunning = false;
		if (null != mDownloaderClientStub) {
			mDownloaderClientStub.disconnect(this);
		}
		super.onStop();
	}

	@Override
	public void onBackPressed() {
		lightView.onBackButton ();
	}

	@Override
	protected void onDestroy() {
		isRunning = false;
		lightView.onDestroy();
		super.onDestroy();
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		Log.d("LIGHTNING", "onActivityResult call");

		if (AndroidFB.fb != null) {
			Log.d("LIGHTNING", "invoke fb authorizeCallback");
			AndroidFB.fb.authorizeCallback(requestCode, resultCode, data);
		}

		super.onActivityResult(requestCode, resultCode, data);
	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) {
		Log.d("LIGHTNING", "onConfigurationChanged");
		super.onConfigurationChanged(newConfig);
	}
}	