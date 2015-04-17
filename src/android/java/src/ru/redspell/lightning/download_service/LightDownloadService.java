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

public class LightDownloadService {
 //public static void download (final String initText, final String filter) {
 public static void download (String url) {
	 Log.d ("LIGHTNING","DownloadService download: " + url);
	 DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

	 request.setDescription("TestReq");
	 request.setTitle("DownloadTest");
	 //request.allowScanningByMediaScanner();
	 request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
	 request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "testFileName");
	 //request.setDestinationUri(path);

	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);

	 final long downloadId = manager.enqueue(request);
	final 	NotificationManager mNotifyManager =
						(NotificationManager) Lightning.activity.getSystemService(Context.NOTIFICATION_SERVICE);
	final 	NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(Lightning.activity);
		mBuilder.setContentTitle("Pizda Download")
				.setContentText("Download in progress");


		final int id  = 1;
		mNotifyManager.notify(id, mBuilder.build());
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

                    Lightning.activity.runOnUiThread(new Runnable() {

                        @Override
                        public void run() {

                            Log.d ("LIGHTNING","progressof :"+ uri + " :" + dl_progress);

																		// Sets the progress indicator to a max value, the
																		// current completion percentage, and "determinate"
																		// state
																		//mBuilder.setProgress(bytes_total, bytes_downloaded, false);
																		// Displays the progress bar for the first time.
                        }
                    });

                    //Log.d(Constants.MAIN_VIEW_ACTIVITY, statusMessage(cursor));
                    cursor.close();
                }

            }
        });


 }

}
