package ru.redspell.lightning.v2;

import com.google.android.vending.expansion.downloader.DownloadProgressInfo;
import com.google.android.vending.expansion.downloader.DownloaderClientMarshaller;
import com.google.android.vending.expansion.downloader.DownloaderServiceMarshaller;
import com.google.android.vending.expansion.downloader.IDownloaderClient;
import com.google.android.vending.expansion.downloader.IStub;
import com.google.android.vending.expansion.downloader.IDownloaderService;
import com.google.android.vending.expansion.downloader.Helpers;

import android.app.PendingIntent;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.TypedArray;
import android.os.Messenger;

import ru.redspell.lightning.expansions.DownloadService;
import ru.redspell.lightning.expansions.XAPKFile;

import ru.redspell.lightning.utils.Log;

public class Expansions {
	private static XAPKFile[] list = null;
	private static IStub stub = null;

	public static XAPKFile[] list() {
		if (list == null) {
			TypedArray rexp = Lightning.activity.getResources().obtainTypedArray(ru.redspell.lightning.R.array.expansions);
			list = new XAPKFile[rexp.length()];

			for (int i = 0; i < rexp.length(); i++) {
				String[] expFileParams = rexp.getString(i).split(",");
				list[i] = new XAPKFile((new Boolean(expFileParams[0])).booleanValue(), (new Integer(expFileParams[1])).intValue(), (new Long(expFileParams[2])).longValue());
			}
		}

		return list;
	}

	private static class DownloaderClient implements IDownloaderClient {
		private IDownloaderService service;

		public native void success();
		public native void fail(String reason);
		public native void progress(long total, long progress, long timeRemain);

	    public void onServiceConnected(Messenger m) {
	    	Log.d("LIGHTNING", "onServiceConnected");

			service = DownloaderServiceMarshaller.CreateProxy(m);
			service.onClientUpdated(stub.getMessenger());
	    }

	    public void onDownloadStateChanged(int newState) {
	    	Log.d("LIGHTNING", "onDownloadStateChanged " + newState);

			switch (newState) {
				case IDownloaderClient.STATE_COMPLETED:
					success();
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
			    	Log.d("LIGHTNING", "fail");
			    	fail(Lightning.activity.getString(Helpers.getDownloaderStringResourceIDFromState(newState)));
			    	break;

			    default: break;
			}
	    }

	    public void onDownloadProgress(DownloadProgressInfo progress) {
	    	Log.d("LIGHTNING", "onDownloadProgress");
	    	progress(progress.mOverallTotal, progress.mOverallProgress, progress.mTimeRemaining);
	    }

	    private static DownloaderClient instance = null;

	    public static DownloaderClient instance() {
	    	if (instance == null) instance = new DownloaderClient();
	    	return instance;
	    }
	}

	private static boolean startService(String pubkey) {
		Log.d("LIGHTNING", "startExpansionDownloadService call");

		DownloadService.setPubKey(pubkey);
		Intent notifierIntent = new Intent(Lightning.activity, Lightning.activity.getClass());
		notifierIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

		PendingIntent pendingIntent = PendingIntent.getActivity(Lightning.activity, 0, notifierIntent, PendingIntent.FLAG_UPDATE_CURRENT);

		int startResult = 0;
		try {
			startResult = DownloaderClientMarshaller.startDownloadServiceIfRequired(Lightning.activity, pendingIntent, DownloadService.class);
		} catch (PackageManager.NameNotFoundException e) {
			e.printStackTrace();
		}

		boolean retval = startResult != DownloaderClientMarshaller.NO_DOWNLOAD_REQUIRED;

		Log.d("LIGHTNING", "startResult " + startResult);
		Log.d("LIGHTNING", "retval " + retval);

		if (retval) {
			Log.d("LIGHTNING", "???1");
			stub = DownloaderClientMarshaller.CreateStub(DownloaderClient.instance(), DownloadService.class);
			Log.d("LIGHTNING", "???2");
			stub.connect(Lightning.activity);
			Log.d("LIGHTNING", "???3");
		}

		return retval;
	}

	public static void download(final String pubKey) {
		Log.d("LIGHTNING", "download expansions...");

	    for (XAPKFile xf : list()) {
            String fileName = Helpers.getExpansionAPKFileName(Lightning.activity, xf.mIsMain, xf.mFileVersion);

            Log.d("LIGHTNING", "checking " + fileName + "...");

            if (!Helpers.doesFileExist(Lightning.activity, fileName, xf.mFileSize, false)) {
            	Log.d("LIGHTNING", fileName + " does not exists, start download service");

            	Lightning.activity.runOnUiThread(new Runnable() {
            		@Override
            		public void run() {
            			Log.d("LIGHTNING", "!!!thread " + android.os.Process.myTid());
            			startService(pubKey);		
            		}
            	});

            	return;
            }

            Log.d("LIGHTNING", "ok");
        }

        DownloaderClient.instance().success();
	}	
}