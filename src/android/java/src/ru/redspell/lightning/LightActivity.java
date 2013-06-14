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
import ru.redspell.lightning.LightActivityResultHandler;
import android.content.res.TypedArray;
import java.util.ArrayList;
import java.util.Iterator;

//import ru.redspell.lightning.payments.Security;

import android.widget.AbsoluteLayout;
import android.widget.EditText;
import android.view.View;
import android.widget.AbsoluteLayout;
import android.view.ViewGroup.LayoutParams;
import android.content.res.Configuration;

import ru.redspell.lightning.payments.google.LightGooglePayments;

/*import com.google.android.gms.common.GooglePlayServicesClient.ConnectionCallbacks;
import com.google.android.gms.common.GooglePlayServicesClient.OnConnectionFailedListener;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.plus.PlusClient;
import com.google.android.gms.common.Scopes;*/



public class LightActivity extends Activity implements IDownloaderClient/*, ConnectionCallbacks, OnConnectionFailedListener */{
	public static LightActivity instance = null;

	protected XAPKFile[] expansions = {};

	public XAPKFile[] getExpansions() {
    	return expansions;
	}

	private final String LOG_TAG = "LIGHTNING";

	public LightView lightView;
	private IStub mDownloaderClientStub;
	private IDownloaderService mRemoteService;

	public AbsoluteLayout viewGrp;
	public static boolean isRunning = false;
	private ArrayList<LightActivityResultHandler> onActivityResultHandlers = new ArrayList();
	public void addOnActivityResultHandler(LightActivityResultHandler h) {
		onActivityResultHandlers.add(h);
	}

/*
	private PlusClient mPlusClient;


	public void onConnected() {
		Log.d("LIGHTNING", "!!!!!!!!!!!!!onConnected");
	}

	public void onDisconnected() {
		Log.d("LIGHTNING", "!!!!!!!!!!!!!onDisconnected");
	}

	public void onConnectionFailed(ConnectionResult result) {
		Log.d("LIGHTNING", "!!!!!!!!!!!!!onConnectionFailed");
	}
*/


	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		// mPlusClient = new PlusClient(this, this, this, Scopes.PLUS_PROFILE);

		instance = this;

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

		TypedArray rexp = getResources().obtainTypedArray(R.array.expansions);
		expansions = new XAPKFile[rexp.length()];

		for (int i = 0; i < rexp.length(); i++) {
			String[] expFileParams = rexp.getString(i).split(",");
			expansions[i] = new XAPKFile((new Boolean(expFileParams[0])).booleanValue(), (new Integer(expFileParams[1])).intValue(), (new Long(expFileParams[2])).longValue());	
		}

		viewGrp = new AbsoluteLayout(this);		
		viewGrp.addView(lightView = new LightView(this));
		setContentView(viewGrp);

	}

	public boolean startExpansionDownloadService() {
		Log.d(LOG_TAG, "startExpansionDownloadService call");

		Intent notifierIntent = new Intent(this, this.getClass());
		notifierIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

		PendingIntent pendingIntent = PendingIntent.getActivity(LightActivity.this, 0, notifierIntent, PendingIntent.FLAG_UPDATE_CURRENT);

		int startResult = 0;
		try {
			startResult = DownloaderClientMarshaller.startDownloadServiceIfRequired(this, pendingIntent, LightExpansionsDownloadService.class);
		} catch (PackageManager.NameNotFoundException e) {
			e.printStackTrace();
		}

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

		switch (newState) {
			case IDownloaderClient.STATE_COMPLETED:
				lightView.expansionsDownloaded();
				break;

		    case STATE_PAUSED_NETWORK_UNAVAILABLE:
		    case STATE_PAUSED_BY_REQUEST:
		    case STATE_PAUSED_WIFI_DISABLED_NEED_CELLULAR_PERMISSION:
		    case STATE_PAUSED_NEED_CELLULAR_PERMISSION:
		    case STATE_PAUSED_WIFI_DISABLED:
		    case STATE_PAUSED_NEED_WIFI:
		    case STATE_PAUSED_ROAMING:
		    case STATE_PAUSED_NETWORK_SETUP_FAILURE:
		    case STATE_PAUSED_SDCARD_UNAVAILABLE:
		    case STATE_FAILED_UNLICENSED:
		    case STATE_FAILED_FETCHING_URL:
		    case STATE_FAILED_SDCARD_FULL:
		    case STATE_FAILED_CANCELED:
		    case STATE_FAILED:
		    	lightView.expansionsError(getString(com.google.android.vending.expansion.downloader.Helpers.getDownloaderStringResourceIDFromState(newState)));
		    	break;

		    default: break;
		}
	}

	public void onDownloadProgress(DownloadProgressInfo progress) {
		Log.d(LOG_TAG, "onDownloadProgress call");
		lightView.expansionsProgress(progress.mOverallTotal, progress.mOverallProgress, progress.mTimeRemaining);
	}

	@Override
	protected void onStart() {
		isRunning = true;
		if (null != mDownloaderClientStub) {
				mDownloaderClientStub.connect(this);
		}
		super.onStart();
		// this.cb.onStart(this);
		// mPlusClient.connect();
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
		// this.cb.onStop(this);
		// mPlusClient.disconnect();
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

		if (LightGooglePayments.instance != null) {
			LightGooglePayments.instance.contextDestroyed(this);
		}

		// this.cb.onDestroy(this);
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		Log.d("LIGHTNING", "onActivityResult call");

		super.onActivityResult(requestCode, resultCode, data);

		Iterator<LightActivityResultHandler> iter = onActivityResultHandlers.iterator();
		while (iter.hasNext()) {
			LightActivityResultHandler r = iter.next();
			r.onActivityResult(requestCode,resultCode,data);
		}

		if (requestCode == LightGooglePayments.REQUEST_CODE && LightGooglePayments.instance != null) {
			LightGooglePayments.instance.onActivityResult(requestCode, resultCode, data);
		}
	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) {
		Log.d("LIGHTNING", "onConfigurationChanged");
		super.onConfigurationChanged(newConfig);
	}

	public static void enableLocalExpansions() {
		com.google.android.vending.expansion.downloader.Constants.LOCAL_EXP_URL = "http://expansions.redspell.ru";
	}	
}	
