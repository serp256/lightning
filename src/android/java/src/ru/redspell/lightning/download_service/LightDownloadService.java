package ru.redspell.lightning.download_service;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;
import android.net.Uri;
import android.app.DownloadManager;
import android.os.Environment;
import android.database.Cursor;
import android.content.Context;

public class LightDownloadService {
 //public static void download (final String initText, final String filter) {
 public static void download (String url) {
	 Log.d ("LIGHTNING","DownloadService download: " + url);
	 DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

	 request.setDescription("TestReq");
	 request.setTitle("DownloadTest");
	 request.allowScanningByMediaScanner();
	 request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
	 request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "testFileName");

	 final DownloadManager manager = (DownloadManager) Lightning.activity.getSystemService(Context.DOWNLOAD_SERVICE);

	 final long downloadId = manager.enqueue(request);



	  Lightning.activity.runOnUiThread(new Runnable() {

            @Override
            public void run() {

                boolean downloading = true;

                while (downloading) {

                    DownloadManager.Query q = new DownloadManager.Query();
                    q.setFilterById(downloadId);

                    Cursor cursor = manager.query(q);
                    cursor.moveToFirst();
                    int bytes_downloaded = cursor.getInt(cursor
                            .getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
                    int bytes_total = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));

                    if (cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)) == DownloadManager.STATUS_SUCCESSFUL) {
                        downloading = false;
                    }

										final int dl_progress = (int) ((bytes_downloaded * 100l) / bytes_total);

                    Lightning.activity.runOnUiThread(new Runnable() {

                        @Override
                        public void run() {

                            Log.d ("LIGHTNING","progress:"+ dl_progress);

                        }
                    });

                    //Log.d(Constants.MAIN_VIEW_ACTIVITY, statusMessage(cursor));
                    cursor.close();
                }

            }
        });


 }

}
