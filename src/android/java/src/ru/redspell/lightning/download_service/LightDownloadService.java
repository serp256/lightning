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
public class LightDownloadService {

	private static final int MY_NOTIFICATION_ID=1;
	NotificationManager notificationManager;
	NotificationCompat.Builder mBuilder;


	/*
	@Override
	 public void onCreate() {
		 super.onCreate();
		 notificationManager = (NotificationManager) Lightning.activity.getSystemService(Context.NOTIFICATION_SERVICE);
		 Context context = Lightning.activity.getApplicationContext();
		 mBuilder = new NotificationCompat.Builder(context);
		 mBuilder.setContentTitle(context.getPackageManager().getApplicationLabel(context.getApplicationInfo()))
			 .setContentText("Download in progress")
			 .setSmallIcon(R.drawable.notif_icon);
	 }


		final int id  = 1;
	public LightDownloadService() {
		super("LightDownloadService");
	}

	int bufDownloaded = 0;
	private void updateProgress(int total, int progress) {
		if (progress == total || (progress - bufDownloaded > (1024 * 50))) {
			Log.d ("LIGHTNING","update progressof :"+ total + " :" + progress);
			bufDownloaded = progress;
			int dl_progress = (int) ((progress* 100l) / total);
			mBuilder.setContentText ("Progress: " + dl_progress + "%");
			mBuilder.setProgress(total, progress, false);
			notificationManager.notify(id, mBuilder.build());
		}
	}
 @Override
  protected void onHandleIntent(Intent intent) {
		Bundle extras = intent.getExtras ();
		String surl  = extras.getString("url");
		String path= extras.getString("path");
		Log.d ("LIGHTNING","OnHadleIntent : " + surl + " path: " + path);
		bufDownloaded = 0;

		try {
				URL url = new URL(surl);
				HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
				urlConnection.setRequestMethod("GET");
				urlConnection.connect();


				File f = new File (Lightning.getStoragePath(),new File(path).getName ());
				FileOutputStream fileOutput = new FileOutputStream(f);
				InputStream inputStream = urlConnection.getInputStream();

				//this is the total size of the file
				int totalSize = urlConnection.getContentLength();
				//variable to store total downloaded bytes
				int downloadedSize = 0;

				byte[] buffer = new byte[1024];
				int bufferLength = 0;

				while ( (bufferLength = inputStream.read(buffer)) > 0 ) {
						fileOutput.write(buffer, 0, bufferLength);
						downloadedSize += bufferLength;
						updateProgress(totalSize,downloadedSize);
				}
				fileOutput.close();

		} catch (java.net.MalformedURLException e) {
			Log.d ("LIGHTNING", e.toString ());
						e.printStackTrace();
		} catch (java.io.IOException e) {
			Log.d ("LIGHTNING", e.toString ());
						e.printStackTrace();
		}
  }


	*/
 //public static void download (final String initText, final String filter) {
 public static void download (String url, String path) {

	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);
		boolean isDownloading = false;
		DownloadManager.Query query = new DownloadManager.Query();
		query.setFilterByStatus(
				DownloadManager.STATUS_PAUSED|
				DownloadManager.STATUS_PENDING|
				DownloadManager.STATUS_RUNNING
);
//| DownloadManager.STATUS_SUCCESSFUL);
		Cursor cur = manager.query(query);
		int col = cur.getColumnIndex(
				DownloadManager.COLUMN_LOCAL_FILENAME);
		for(cur.moveToFirst(); !cur.isAfterLast(); cur.moveToNext()) {
			Log.d ("LIGHTNING", "CHECK: " + path + " " + cur.getString(col));
				isDownloading = isDownloading || (path.equals(cur.getString(col)));
		}
		cur.close();

		Log.d ("LIGHTNING", "is downloading: " +isDownloading);
		File folder1 = new File(path);
		Log.d ("LIGHTNING", "FILE EXISTS: " + folder1.exists());
		if (folder1.exists() && !isDownloading) {
		Log.d ("LIGHTNING", "DELETE: ");
		folder1.delete ();
		}

if (!isDownloading) {

	 DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

	 request.setDescription("TestReq2");
request.setVisibleInDownloadsUi(false);
	 request.setTitle("DownloadTest");
	 //request.allowScanningByMediaScanner();
	 //request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_HIDDEN);
	 request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
	 File f = new File (path);


	 request.setDestinationInExternalFilesDir(Lightning.activity,null,f.getName());


	 final long downloadId = manager.enqueue(request);
}
/*
	  Lightning.activity.runOnUiThread(new Runnable() {

            @Override
            public void run() {

                boolean downloading = true;

                while (downloading) {

                    DownloadManager.Query q = new DownloadManager.Query();
                    q.setFilterById(downloadId);

                    Cursor cursor = manager.query(q);
                    cursor.moveToFirst();
                    final int bytes_downloaded = cursor.getInt(cursor
                            .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
                    final int bytes_total = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

										final String uri =cursor.getString(cursor.getColumnIndex(DownloadManager.COLUMN_URI));

                    if (cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)) == DownloadManager.STATUS_SUCCESSFUL) {
                        downloading = false;
                    }

										final int dl_progress = (int) ((bytes_downloaded * 100l) / bytes_total);

//										Log.d ("LIGHTNING","11 progressof :"+ uri + " :" + dl_progress);
                    cursor.close();
                }

            }
        });
*/


 }

}
