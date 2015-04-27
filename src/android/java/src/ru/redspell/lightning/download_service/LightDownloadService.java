package ru.redspell.lightning.download_service;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;
import android.net.Uri;
import android.app.DownloadManager;
import android.os.Environment;
import android.database.Cursor;
import android.content.Context;
import android.app.NotificationManager;
import android.support.v4.app.NotificationCompat;
import ru.redspell.lightning.R;
import android.os.Bundle;
import android.content.Intent;
import android.app.IntentService;
import java.io.*;
import java.net.*;
import android.content.BroadcastReceiver;
import android.app.PendingIntent;
import android.content.IntentFilter;
import java.util.Timer;
import java.util.TimerTask;
import java.util.ArrayList;
import java.util.List;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.security.MessageDigest;
public class LightDownloadService {

	public static boolean appRunning = false;
	public static boolean needPush = true;

	private static int successDownload;
	private static int failDownload;
	private static int progressDownload;
	private static boolean compress=true;

	private static Timer timer; 

	public static class DownloadCompleteReceiver extends BroadcastReceiver{
		@Override
			public void onReceive(Context context, Intent intent) {
				String action = intent.getAction();
				Log.d ("LIGHTNING","RECEIVE " + action );
				if (timer != null) {
					timer.cancel ();
				};
				checkDownloadStatus (context, intent);
			}
	};

	private static void unzipAndSuccess(String zipFile) {
		if (compress) {
			File zip = new File (zipFile);
			String outputFolder = zip.getParent();
			List<String> filesList = new ArrayList<String> ();

			Log.d ("LIGHTNING","unzip to" + outputFolder + " " + zipFile);
	 
			 try {
				 FileInputStream fis = new FileInputStream(zipFile); 
				 ZipInputStream zin  = new ZipInputStream(new BufferedInputStream(fis));
				 ZipEntry entry;

				 while((entry = zin.getNextEntry()) != null) {
					 int BUFFER = 4096;
					 filesList.add (entry.getName());
					 FileOutputStream fos = new FileOutputStream(outputFolder + File.separator + entry.getName());
					 BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
					 int count;
					 byte data[] = new byte[BUFFER];
					 while ((count = zin.read(data, 0, BUFFER)) != -1) {
						 dest.write(data, 0, count);
					 }
					 dest.close();
					 zin.closeEntry ();
				 }

				 zin.close();
				 fis.close();

				 String[] files = new String[filesList.size()];
				 files = filesList.toArray(files);

				 zip.delete ();
				 downloadSuccess(files);
			} catch (IOException ex){
				Log.d ("LIGHTNING","UNZIP Failed " + ex.toString());
				downloadFail ("Fail when unzipping:" + ex.toString());
			}
		}
		else {
			File f = new File(zipFile);
			String[] files = {f.getName()};
			downloadSuccess(files);
		}
	}

	private static void downloadFail (String reason) {
		if (appRunning) {
			(new DownloadFail(successDownload, failDownload, progressDownload, reason)).run ();
		}
	}

	private static void downloadSuccess (String[] files) {
		if (appRunning) {
			(new DownloadSuccess(successDownload, failDownload, progressDownload, files)).run ();
		}
	}
	
	private static void checkDownloadStatus (Context context, Intent intent){
	 final DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
	 long id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID,0);
	 Log.d ("LIGHTNING","downloadId: " + id + " appRunning " + appRunning + " needpush " + needPush);

	 DownloadManager.Query query = new DownloadManager.Query();
	 query.setFilterById(id);
	 Cursor cursor = manager.query(query);
	 String downloadResult = "Download...";
	 if(cursor.moveToFirst()){
		int columnIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS);
		int status = cursor.getInt(columnIndex);
		int columnReason = cursor.getColumnIndex(DownloadManager.COLUMN_REASON);
		int reason = cursor.getInt(columnReason);
		final String fname =cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_FILENAME));
	 
		switch(status){
		case DownloadManager.STATUS_FAILED:
		 String failedReason = "FILE_NOT_FOUND";
		 switch(reason){
		 case DownloadManager.ERROR_CANNOT_RESUME:
			failedReason = "ERROR_CANNOT_RESUME";
			break;
		 case DownloadManager.ERROR_DEVICE_NOT_FOUND:
			failedReason = "ERROR_DEVICE_NOT_FOUND";
			break;
		 case DownloadManager.ERROR_FILE_ALREADY_EXISTS:
			failedReason = "ERROR_FILE_ALREADY_EXISTS";
			break;
		 case DownloadManager.ERROR_FILE_ERROR:
			failedReason = "ERROR_FILE_ERROR";
			break;
		 case DownloadManager.ERROR_HTTP_DATA_ERROR:
			failedReason = "ERROR_HTTP_DATA_ERROR";
			break;
		 case DownloadManager.ERROR_INSUFFICIENT_SPACE:
			failedReason = "ERROR_INSUFFICIENT_SPACE";
			break;
		 case DownloadManager.ERROR_TOO_MANY_REDIRECTS:
			failedReason = "ERROR_TOO_MANY_REDIRECTS";
			break;
		 case DownloadManager.ERROR_UNHANDLED_HTTP_CODE:
			failedReason = "ERROR_UNHANDLED_HTTP_CODE";
			break;
		 case DownloadManager.ERROR_UNKNOWN:
			failedReason = "ERROR_UNKNOWN";
			break;
		 }

		 Log.d ("LIGHTNING", "FAILED: " + failedReason);
		 downloadFail (failedReason);
		 downloadResult = "Download failed";
		 break;
		case DownloadManager.STATUS_PAUSED:
		 String pausedReason = "";
		
		 switch(reason){
		 case DownloadManager.PAUSED_QUEUED_FOR_WIFI:
			pausedReason = "PAUSED_QUEUED_FOR_WIFI";
			break;
		 case DownloadManager.PAUSED_UNKNOWN:
			pausedReason = "PAUSED_UNKNOWN";
			break;
		 case DownloadManager.PAUSED_WAITING_FOR_NETWORK:
			pausedReason = "PAUSED_WAITING_FOR_NETWORK";
			break;
		 case DownloadManager.PAUSED_WAITING_TO_RETRY:
			pausedReason = "PAUSED_WAITING_TO_RETRY";
			break;
		 }
		
		 Log.d ("LIGHTNING", "PAUSED: " + pausedReason);
		 downloadFail (pausedReason);
		 downloadResult = "Download failed";
		 break;
		case DownloadManager.STATUS_PENDING:
		 Log.d ("LIGHTNING", "PENDING: " );
		 downloadFail ("Pending");
		 downloadResult = "Download failed";
		 break;
		case DownloadManager.STATUS_RUNNING:
		 Log.d ("LIGHTNING", "RUNNING: " );
		 downloadResult = "Download failed";
		 downloadFail ( "Still running");
		 break;
		case DownloadManager.STATUS_SUCCESSFUL:
		 Log.d ("LIGHTNING", "SUCCESSFUL: " );
		 downloadResult = "Download complete";

		 //UNZIP
		 unzipAndSuccess(fname);
		 break;
		}
	 }
	 cursor.close();

	 Log.d ("LIGHTNING","end of downloading " + needPush);
	 if (needPush ) {
		 Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());

		 Log.d ("LIGHTNING","package " + context.getPackageName());

		 PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		 NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		 NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(context);
		 mBuilder.setContentTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()))
			 .setContentText(downloadResult)
			 .setContentIntent(pNotifIntnt)
			 .setSmallIcon(R.drawable.notif_icon)
			 .setDefaults(android.app.Notification.DEFAULT_ALL)
			 .setAutoCancel(true);
		 notificationManager.notify(111, mBuilder.build());
	 }
}

private static boolean checkMD5 (String md5, File file) { 
	try {
		FileInputStream is = new FileInputStream(file.getPath());
		MessageDigest md = MessageDigest.getInstance("MD5");
		md.reset();
		int byteArraySize = 2048;
		byte[] bytes = new byte[byteArraySize];
		int numBytes;
		while ((numBytes = is.read(bytes)) != -1) {
			md.update(bytes, 0, numBytes);
		}
		byte[] hash = md.digest();
		StringBuffer hexString = new StringBuffer();
		for (int i = 0; i < hash.length; i++) {
			if ((0xff & hash[i]) < 0x10) {
				hexString.append("0"
						+ Integer.toHexString((0xFF & hash[i])));
			} else {
				hexString.append(Integer.toHexString(0xFF & hash[i]));
			}
		}
		String result = hexString.toString();
		Log.d ("LIGHTNING", md5 + " = " + result);
		return (md5.equals (result));
	}
	catch (java.lang.Exception exc) {
		Log.d ("LIGHTNING",exc.toString());
		return false;
	}
}

	private static void setProgressTimer (final long id) {
			int delay = 1000; 
			int period = 1000; 
			if (timer != null) {
				timer.cancel ();
			}
			Log.d("LIGHTNING","downloadid " + id);
			final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);
			timer = new Timer(); 
			timer.scheduleAtFixedRate(new TimerTask() { 
				public void run() { 
					DownloadManager.Query q = new DownloadManager.Query();
					q.setFilterById(id);

					Cursor cursor = manager.query(q);
					cursor.moveToFirst ();
						final long bytes_downloaded = cursor.getLong(cursor .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
						final long bytes_total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

					cursor.close();
					if (appRunning) {
						(new DownloadProgress(progressDownload,(double)bytes_downloaded, (double) bytes_total)).run();
					}
					else {
						if (timer != null) {
							timer.cancel ();
						};
					}
					if (bytes_downloaded == bytes_total) {
						if (timer != null) {
							timer.cancel ();
						};
					}
				} 
			}, delay, period);
	}
private static void enqueueRequest (String url, String path) {
	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);
	 Log.d("LIGHTNING","start download");
	 DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

	 File f = new File (path);
	 request.setVisibleInDownloadsUi(false);
	 Context context = Lightning.activity.getApplicationContext ();
	 request.setTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()));
	 request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
	 request.setDestinationInExternalFilesDir(Lightning.activity,null,f.getName());

	 long downloadId = manager.enqueue(request);
	 setProgressTimer(downloadId);

}
 public static void download (boolean isCompress, String md5, String url, String path, int successCb, int failCb, final int progressCb) {
	 Log.d ("LIGHTNING", "Java download: " + url + " with compress: " + isCompress);
	 compress = isCompress;
	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);
		boolean isDownloading = false;
		long downloadId = -1;
			 successDownload = successCb;
			 failDownload = failCb;
			 progressDownload = progressCb;
		DownloadManager.Query query = new DownloadManager.Query();
		query.setFilterByStatus(
				DownloadManager.STATUS_PAUSED|
				DownloadManager.STATUS_PENDING|
				DownloadManager.STATUS_RUNNING
    );
		Cursor cur = manager.query(query);
		int col = cur.getColumnIndex(DownloadManager.COLUMN_LOCAL_FILENAME);
		for(cur.moveToFirst(); !cur.isAfterLast(); cur.moveToNext()) {
			Log.d ("LIGHTNING", "CHECK: " + path + " " + cur.getString(col) + " " + cur.getString(cur.getColumnIndex(DownloadManager.COLUMN_URI)) + " " + cur.getString(cur.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI)));
				if (path.equals(cur.getString(col))) {
					isDownloading = true;
					downloadId = cur.getLong(cur.getColumnIndex(DownloadManager.COLUMN_ID));
					break;
				}
		}
		cur.close();

		Log.d ("LIGHTNING", "is downloading: " +isDownloading);
		File folder1 = new File(path);
		Log.d ("LIGHTNING", "FILE EXISTS: " + folder1.exists());
		if (folder1.exists() && !isDownloading) {

			//String md5 = "8491981a2935d4e5e508c4208726975a";
			if (!checkMD5 (md5,folder1)) {
				Log.d ("LIGHTNING","should delete"); 
				folder1.delete ();
				enqueueRequest(url,path);
			}
			else {
				unzipAndSuccess(folder1.getPath());
		  }
		}
		else 
			if (!isDownloading) {
				enqueueRequest(url,path);
			}
			else {
				setProgressTimer(downloadId);
			}

 }

  private static abstract class Callback implements Runnable {
		protected int success;
		protected int fail;
		protected int progress;

		public abstract void run();

		public Callback(int success, int fail, int progress) {
			this.success = success;
			this.fail = fail;
			this.progress= progress;
		}
	}

	private static class DownloadSuccess extends Callback {
		protected String[] files;
		public DownloadSuccess(int success, int fail, int progress, String[]files) {
			super(success, fail, progress);
			this.files = files;
		}

		public native void nativeRun(int success, int fail, int progress, String[] files);

		public void run() {
			nativeRun(success, fail, progress, files);
		}
	}

	private static class DownloadFail extends Callback {
			private String reason;

			public DownloadFail(int success, int fail, int progress, String reason) {
				super(success, fail, progress);
				this.reason = reason;
			}

			public native void nativeRun(int success, int fail, int progress, String reason);

			public void run() {
				nativeRun(success, fail, progress, reason);
			}
	}


  private static class DownloadProgress implements Runnable {
		protected int callback;
		protected double progress;
		protected double total;

		public DownloadProgress (int callback, double progress, double total) {
			this.callback = callback;
			this.progress = progress;
			this.total    = total;
		}

		public native void nativeRun(int callback, double progress, double total);

		public void run() {
			//Log.d ("LIGHTNING","Download progress " + progress + " " +total);
			nativeRun(callback, progress, total);
		}
	}

/*
  private static class DownloadFinishSuccess implements Runnable {
		protected int success;
		protected int fail;
		protected int progress;

		public DownloadFinishSuccess (int success, int fail, int progress) {
			this.success = success;
			this.fail = fail;
			this.fail = progress;
		}

		public native void nativeRun(int success, int fail);

		public void run() {
			nativeRun(success, fail);
		}
	}

  private static class DownloadFinishFail extends DownloadFinishSuccess {
		protected String reason;

		public DownloadFinishFail (int success, int fail, String reason) {
			super(success,fail);
			this.reason= reason;
		}

		public native void nativeRun(int success, int fail, String reason);

		public void run() {
			nativeRun(success, fail, reason);
		}
	}
	*/


}
