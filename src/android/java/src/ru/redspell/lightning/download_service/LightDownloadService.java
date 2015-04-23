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
import 	android.app.IntentService;
import 	java.io.*;
import 	java.net.*;
import android.content.BroadcastReceiver;
import android.app.PendingIntent;
import android.content.IntentFilter;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Hashtable;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
public class LightDownloadService {

	public static boolean appRunning = false;
	public static boolean needPush = true;
	private static class DownloadCallbacks {
		protected int success;
		protected int fail;
		protected int progress;
		public DownloadCallbacks (int success, int fail, int progress) {
			this.success= success;
			this.fail= fail;
			this.progress= progress;
		}
	}

	private static Hashtable<java.lang.Long,DownloadCallbacks> callbacksHash; 

	private static int successDownload;
	private static int failDownload;
	private static int progressDownload;
	private static boolean compress;

	private static long old_bytes_downloaded = 0;
	private static long old_bytes_total = 0;
	private static long bytes_downloaded = 0;
	private static long bytes_total = 0;

	private static Timer timer; 
	private static void close () {
		callbacksHash = null;

	}

	public static class DownloadCompleteReceiver extends BroadcastReceiver{
		@Override
			public void onReceive(Context context, Intent intent) {
				String action = intent.getAction();
				Log.d ("LIGHTNING","RECEIVE " + action );
				timer.cancel ();
				checkDownloadStatus (context, intent);
			}
	};

	private static void unzip(String zipFile) {
		if(zipFile.contains(".")) {
			//String filename = zipFile.substring(0, zipFile.lastIndexOf('.')) 
			String outputFolder = new File(zipFile).getParent();
			Log.d ("LIGHTNING","unzip to" + outputFolder + " " + zipFile);
			 
					 try{
						 FileInputStream fis = new FileInputStream(zipFile); 
						 ZipInputStream zin = new    ZipInputStream(new BufferedInputStream(fis));
						 ZipEntry entry;
							Log.d ("LIGHTNING", "entry ");
						 while((entry = zin.getNextEntry()) != null) {
							int BUFFER = 2048;
							Log.d ("LIGHTNING", "entry " + (outputFolder + File.separator +entry.getName()));
							FileOutputStream fos = new FileOutputStream(outputFolder + File.separator +entry.getName());
							BufferedOutputStream dest = new BufferedOutputStream(fos, BUFFER);
							int count;
							byte data[] = new byte[BUFFER];
							while ((count = zin.read(data, 0, BUFFER)) != -1) {
								Log.d ("LIGHTNING", "count " + count);
								   //System.out.write(x);
									    dest.write(data, 0, count);
									 }
								Log.d ("LIGHTNING", "__count " + count);
							dest.flush();
							dest.close();

						 }
							zin.close();
							fis.close();
							/*
						//get the zip file content
						ZipInputStream zis = new ZipInputStream(new BufferedInputStream(new FileInputStream(zipFile)));
						//get the zipped file list entry
						ZipEntry ze = zis.getNextEntry();
			 
						while(ze!=null){


							ByteArrayOutputStream baos = new ByteArrayOutputStream();
							             byte[] buffer = new byte[1024];
													              int count;

			 
							 String fileName = ze.getName();
								 File newFile = new File(outputFolder + File.separator + fileName);
			 
								 Log.d ("LIGHTNING","read entry" + fileName);
									//create all non exists folders
									//else you will hit FileNotFoundException for compressed folder
									new File(newFile.getParent()).mkdirs();
			 
									FileOutputStream fout = new FileOutputStream(newFile);             
									while((count = zis.read(buffer)) != -1) 
									{
										baos.write(buffer, 0, count);
										byte[] bytes = baos.toByteArray();
										fout.write(bytes);             
										baos.reset();
									}

			 
			 
									fout.close();   
									ze = zis.getNextEntry();
						}
			 
							zis.closeEntry();
						zis.close();
			 
						Log.d ("LIGHTNING","UNZIP DONE " + zipFile + " to " + outputFolder);
						*/
					}catch(IOException ex){
						Log.d ("LIGHTNING","UNZIP Failed " + ex.toString());
					}
		}
	}

	private static void downloadFail (long id, String reason) {
		if (appRunning) {
			(new DownloadFail(successDownload, failDownload, progressDownload, reason)).run ();
		}
		/*
		if (callbacksHash != null) {
			DownloadCallbacks obj = callbacksHash.get(id);
			if (obj != null) {
			 (new DownloadFail(obj.success,obj.fail,obj.progress, reason)).run ();
			}
		}
		*/
	}

	private static void downloadSuccess (long id) {
		/*
		if (callbacksHash != null) {
			DownloadCallbacks obj = callbacksHash.get(id);
			if (obj != null) {
				Log.d ("LIGHTNING", "success id " + obj.success);

			 (new DownloadSuccess(obj.success,obj.fail,obj.progress)).run ();
			}
		}
		*/


		if (appRunning) {
//		 final DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
					 (new DownloadSuccess(successDownload, failDownload, progressDownload)).run ();
				 }
	}
	

	private static void checkFinishAll (boolean isSuccess, String reason){
		/*
		if (appRunning) {
//		 final DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
				 if (isSuccess) {
					 (new DownloadSuccess(successDownload, failDownload, progressDownload)).run ();
					 close ();
				 }
				 else  {
					 (new DownloadFail(successDownload, failDownload, progressDownload, reason)).run ();
					 close();
				 }
		}
		*/
	}

	private static void checkDownloadStatus (Context context, Intent intent){
	 final DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
	 long id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID,0);
	 Log.d ("LIGHTNING","downloadId: " + id + " appRunning " + appRunning + " needpush " + needPush);

		 boolean stillDownloading = false;

/*		 boolean stillDownloading = false;
				DownloadManager.Query query2 = new DownloadManager.Query();
				query2.setFilterByStatus(
						DownloadManager.STATUS_PAUSED|
						DownloadManager.STATUS_PENDING|
						DownloadManager.STATUS_RUNNING
				);
				Cursor cur = manager.query(query2);
				for(cur.moveToFirst(); !cur.isAfterLast(); cur.moveToNext()) {
						stillDownloading = true;
						break;
				}
				cur.close();
				*/



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
		Log.d ("LIGHTNING", "COMPLETE of: " + cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_LOCAL_FILENAME)));
	 
		switch(status){
		case DownloadManager.STATUS_FAILED:
		 String failedReason = "UNKNOWN ERROR";
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
		 //if (appRunning) {
			 downloadFail (id, failedReason);
			 if (!stillDownloading) {
			 checkFinishAll(false,failedReason);
			 }
		// }
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
		 //if (appRunning) {
			 downloadFail (id, pausedReason);
			 if (!stillDownloading) {
			 checkFinishAll(false,pausedReason);
			 }
		 //}
		 downloadResult = "Download failed";
		 break;
		case DownloadManager.STATUS_PENDING:
		 Log.d ("LIGHTNING", "PENDING: " );
		 //if (appRunning) {
			 downloadFail (id,"Pending");
			 if (!stillDownloading) {
			 checkFinishAll(false,"Pending");
			 }
		 //}
		 downloadResult = "Download failed";
		 break;
		case DownloadManager.STATUS_RUNNING:
		 Log.d ("LIGHTNING", "RUNNING: " );
		 downloadResult = "Download failed";
		 //if (appRunning) {
			 downloadFail (id, "Still running");
			 if (!stillDownloading) {
			 checkFinishAll(false,"Still running");
			 }
		// }
		 break;
		case DownloadManager.STATUS_SUCCESSFUL:
		 Log.d ("LIGHTNING", "SUCCESSFUL: " );
		 downloadResult = "Download complete";

		 /*if (appRunning) {
		 (new DownloadSuccess(success,fail,progress)).run ();
		 }
		 */

		 //if (appRunning) {
			 downloadSuccess(id);
			 if (compress==true) {
				 unzip (fname);
			 }
			 if (!stillDownloading) {
			 checkFinishAll(true,null);
			 }
		 //}
		 /*
			DownloadManager.Query query2 = new DownloadManager.Query();
			query2.setFilterByStatus(
					DownloadManager.STATUS_PAUSED|
					DownloadManager.STATUS_PENDING|
					DownloadManager.STATUS_RUNNING
			);
			Cursor cur = manager.query(query2);
			for(cur.moveToFirst(); !cur.isAfterLast(); cur.moveToNext()) {
				Log.d ("LIGHTNING", "iter query");
					stillDownloading = true;
					break;
			}
			cur.close();
		 if (appRunning && !stillDownloading) {
			 (new DownloadFinishSuccess(successDownload, failDownload)).run ();
		 }
		 */
		 break;
		}
	 }
	 cursor.close();

	 if (needPush && !stillDownloading) {
		 Intent startIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());

		 PendingIntent pNotifIntnt = PendingIntent.getActivity(context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT);
		 NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
		 NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(context);
		 mBuilder.setContentTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()))
			 .setContentText(downloadResult)
			 .setContentIntent(pNotifIntnt)
			 .setSmallIcon(R.drawable.notif_icon)
			 .setDefaults(android.app.Notification.DEFAULT_ALL)
			 .setAutoCancel(true);
		 notificationManager.notify(11, mBuilder.build());
	 }
}


 public static void init (int successCb, int failCb, final int progressCb) {
	 successDownload = successCb;
	 failDownload = failCb;
	 progressDownload = progressCb;
	 callbacksHash = new Hashtable();

		int delay = 3000; // delay for 1 sec. 
		int period = 1000; // repeat every 10 sec. 
		final Timer timer = new Timer(); 
		final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);


				DownloadManager.Query q = new DownloadManager.Query();

				Cursor cursor = manager.query(q);
				for(cursor.moveToFirst(); !cursor.isAfterLast(); cursor.moveToNext()) {
					old_bytes_downloaded += cursor.getLong(cursor .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
					old_bytes_total += cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

				}
				cursor.close();


		timer.scheduleAtFixedRate(new TimerTask() { 
			public void run() { 
				Log.d ("LIGHTNING","run timer");

					bytes_downloaded = - old_bytes_downloaded;
					bytes_total = - old_bytes_total;

							DownloadManager.Query q = new DownloadManager.Query();

							Cursor cursor = manager.query(q);
							for(cursor.moveToFirst(); !cursor.isAfterLast(); cursor.moveToNext()) {
								bytes_downloaded += cursor.getLong(cursor .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
								bytes_total += cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

							}
							cursor.close();
							if (appRunning) {
								(new DownloadProgress(progressCb,(double)bytes_downloaded, (double) bytes_total)).run();
							}
							else {
								timer.cancel ();
							}
						if (bytes_downloaded == bytes_total) {
							timer.cancel ();
						}
							/*
							try {
								Thread.sleep(2000);
							}catch (Exception e) {
								Log.d ("LIGHTNING",e.toString());

							}    
							*/
				} 
			}, delay, period);
 }

 public static void download (boolean isCompress, String url, String path, int successCb, int failCb, final int progressCb) {
	 Log.d ("LIGHTNING", "Java download: " + url + "compress  " + isCompress);
	 compress = isCompress;
	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);
		boolean isDownloading = false;
		long downloadId = -1;
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
			Log.d ("LIGHTNING", "DELETE ");
			folder1.delete ();
		}

		if (!isDownloading) {
			Log.d ("LIGHTNING", "enqueue");

		 DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

		 File f = new File (path);
		 request.setDescription(f.getName());
		 request.setVisibleInDownloadsUi(false);
		 Context context = Lightning.activity.getApplicationContext ();
		 request.setTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()));
		 request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
		 request.setDestinationInExternalFilesDir(Lightning.activity,null,f.getName());

		 final long id = manager.enqueue(request);

			 successDownload = successCb;
			 failDownload = failCb;
			 progressDownload = progressCb;

				int delay = 3000; // delay for 1 sec. 
				int period = 1000; // repeat every 10 sec. 
				timer = new Timer(); 
				timer.scheduleAtFixedRate(new TimerTask() { 
					public void run() { 
						Log.d ("LIGHTNING","run timer");


									DownloadManager.Query q = new DownloadManager.Query();
									q.setFilterById(id);

									Cursor cursor = manager.query(q);
									cursor.moveToFirst ();
										final long bytes_downloaded = cursor.getLong(cursor .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
										final long bytes_total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

									cursor.close();
									if (appRunning) {
						Log.d ("LIGHTNING","progress");
										(new DownloadProgress(progressCb,(double)bytes_downloaded, (double) bytes_total)).run();
									}
									else {
										timer.cancel ();
									}
								if (bytes_downloaded == bytes_total) {
									timer.cancel ();
								}
						} 
					}, delay, period);
















		 //callbacksHash.put(id, new DownloadCallbacks(successCb, failCb, progressCb));
		 Log.d ("LIGHTNING","download id:" + id);

		 /*
								DownloadManager.Query q = new DownloadManager.Query();
								q.setFilterById(id);

								Cursor cursor = manager.query(q);
								cursor.moveToFirst();
								final long total = cursor.getLong(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
								cursor.close ();

									if (appRunning) {
										Log.d ("LIGHTNING","addding "+ total + " " + bytes_total);
										(new DownloadProgress(progressDownload,(double)bytes_downloaded, (double) (bytes_total+total))).run();
									}
									*/
		 /*
			int delay = 1000; // delay for 1 sec. 
			int period = 1000; // repeat every 10 sec. 
			final Timer timer = new Timer(); 
			timer.scheduleAtFixedRate(new TimerTask() { 
				public void run() { 
					Log.d ("LIGHTNING","run");
						boolean downloading = true;

						int prev_bytes_downloaded = 0;

								DownloadManager.Query q = new DownloadManager.Query();
								q.setFilterById(id);

								Cursor cursor = manager.query(q);
								cursor.moveToFirst();
								final int bytes_downloaded = cursor.getInt(cursor
												.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
								final int bytes_total = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

								final String uri =cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_URI));

								if (cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)) != DownloadManager.STATUS_SUCCESSFUL) {

								final int dl_progress = (int) ((bytes_downloaded * 100l) / bytes_total);

								if (bytes_downloaded != prev_bytes_downloaded) {
									Log.d ("LIGHTNING","progressof :"+ uri + " :" + dl_progress);
									if (appRunning) {
										(new DownloadProgress(progressCb,(double)bytes_downloaded, (double) bytes_total)).run();
									}
									else {
										timer.cancel ();
									}
									prev_bytes_downloaded = bytes_downloaded;
								}
								if (bytes_downloaded == bytes_total) {
									timer.cancel ();
								}
								}
								else {
									timer.cancel ();
								}
								cursor.close();
								/*
								try {
									Thread.sleep(2000);
								}catch (Exception e) {
									Log.d ("LIGHTNING",e.toString());

								}    
								*/
		 /*
					} 
				}, delay, period);
		*/
		}
		else {
			//(new FreeCallbacks (successCb,  failCb, progressCb)).run ();
		//	if (downloadId != -1) {
			//	callbacksHash.put(downloadId, new DownloadCallbacks(successCb, failCb, progressCb));
		//	}
		//	else {
				//FREE CALLBACKS
		//	}
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
		public DownloadSuccess(int success, int fail, int progress) {
			super(success, fail, progress);
		}

		public native void nativeRun(int success, int fail, int progress);

		public void run() {
			nativeRun(success, fail, progress);
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
