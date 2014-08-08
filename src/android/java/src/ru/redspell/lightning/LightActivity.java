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
import java.util.ArrayList;
import java.util.Iterator;

//import ru.redspell.lightning.payments.Security;

import android.widget.AbsoluteLayout;
import android.widget.EditText;
import android.view.View;
import android.widget.AbsoluteLayout;
import android.view.ViewGroup.LayoutParams;
import android.content.res.Configuration;
import com.google.android.gms.common.GooglePlayServicesUtil;
import 	com.google.android.gms.common.ConnectionResult;

import ru.redspell.lightning.payments.google.LightGooglePayments;

/*import com.google.android.gms.common.GooglePlayServicesClient.ConnectionCallbacks;
import com.google.android.gms.common.GooglePlayServicesClient.OnConnectionFailedListener;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.plus.PlusClient;
import com.google.android.gms.common.Scopes;*/


import java.util.concurrent.CopyOnWriteArrayList;

public class LightActivity extends Activity implements IDownloaderClient/*, ConnectionCallbacks, OnConnectionFailedListener */{
	public class MarketType {
		public static final String GOOGLE = "google";
		public static final String AMAZON = "amazon";
	}

	public String marketType() {
		return MarketType.GOOGLE;
	}

	// private static ArrayList<IUiLifecycleHelper> uiLfcclHlprs = new ArrayList();
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();

	public static void addUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.add(helper);
	}

	public static void removeUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.remove(helper);
	}

	public static LightActivity instance = null;

	protected XAPKFile[] expansions = {};

	public XAPKFile[] getExpansions() {
    	return expansions;
	}

	private final String LOG_TAG = "LIGHTNING";
	private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

	public boolean isPlayServicesAvailable = false;
	public LightView lightView;
	private IStub mDownloaderClientStub;
	private IDownloaderService mRemoteService;

	public AbsoluteLayout viewGrp;
	public static boolean isRunning = false;


	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		instance = this;

		Log.d("LIGHTNING", "savedState " + (savedInstanceState != null));
		
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

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onCreate(savedInstanceState);
		};

		if (marketType() == MarketType.GOOGLE) {
			checkPlayServices();	
		}

		addUiLifecycleHelper(new LightMediaPlayer.LifecycleHelper());
	}

	public boolean startExpansionDownloadService(String pubKey) {
		Log.d(LOG_TAG, "startExpansionDownloadService call");

		LightExpansionsDownloadService.setPubKey(pubKey);
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
		Log.d(LOG_TAG, "onDownloadStateChanged call " + newState);

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
		Log.d(LOG_TAG, "onDownloadProgress call " + progress.mOverallTotal + " " + progress.mOverallProgress + " " + progress.mTimeRemaining);
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

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onPause();
		}		
	}

	@Override
	protected void onResume() {
		isRunning = true;
		super.onResume();
		lightView.onResume();

		if (null != mDownloaderClientStub) {
			mDownloaderClientStub.connect(this);
		}

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onResume();
		}
	}

	@Override
	protected void onStop() {
		isRunning = false;
		if (null != mDownloaderClientStub) {
			mDownloaderClientStub.disconnect(this);
		}
		super.onStop();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onStop();
		}
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

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onDestroy();
		}		
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		Log.d("LIGHTNING", "onActivityResult call " +  + Thread.currentThread().getId());

		super.onActivityResult(requestCode, resultCode, data);

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onActivityResult(requestCode, resultCode, data);
		}

		if (requestCode == LightGooglePayments.REQUEST_CODE && LightGooglePayments.instance != null) {
			LightGooglePayments.instance.onActivityResult(requestCode, resultCode, data);
		}
	}

	@Override
	protected void onSaveInstanceState(Bundle outState) {
		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onSaveInstanceState(outState);
		}
	}

	public class ForceStageRenderRunnable implements Runnable {
		private String reason = null;

		public ForceStageRenderRunnable(String reason) {
			this.reason = reason;
		}

		public native void run(String reason);

		public void run() {
			run(reason);
		}
	}

	public void forceStageRender(String reason) {
		lightView.queueEvent(new ForceStageRenderRunnable(reason));
	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) {
		super.onConfigurationChanged(newConfig);
		forceStageRender("onConfigurationChanged");
	}

	public static void enableLocalExpansions() {
		com.google.android.vending.expansion.downloader.Constants.LOCAL_EXP_URL = "http://expansions.redspell.ru";
	}


	private static native void mlSetReferrer(String type,String nid);

	public void convertIntent() {
		Bundle extras = getIntent().getExtras();
		if (extras != null) {
			String nid = extras.getString("localNotification");
			Log.d("LIGHTNING", "nid: " + nid);
			if (nid != null) mlSetReferrer("local",nid);
			else {
				nid = extras.getString("remoteNotification");
				if (nid != null) mlSetReferrer("remote",nid);
			}
		}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		Log.d("LIGHTNING","onNewIntent");
		setIntent(intent);
		if (lightView != null && lightView.rendererReady) {
				lightView.queueEvent(new Runnable() {
				 @Override
				 public void run() {
					 convertIntent();
				 }
				});
		}
	}


	private void checkPlayServices() {
		int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(this);
    if (resultCode != ConnectionResult.SUCCESS) {
        if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
            GooglePlayServicesUtil.getErrorDialog(resultCode, this, PLAY_SERVICES_RESOLUTION_REQUEST).show();
        };
        isPlayServicesAvailable = false;
    }
		isPlayServicesAvailable = true;
	};



	public void onLightEvent(String event_key) {
	
	};
}	
