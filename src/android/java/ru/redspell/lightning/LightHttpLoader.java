package ru.redspell.lightning;

import android.os.AsyncTask;
import java.net.URL;
import java.net.HttpURLConnection;
import java.io.OutputStreamWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLConnection;
import java.io.BufferedInputStream;
import java.io.FileOutputStream;
import android.util.Log;
import java.io.FilterInputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.*;


public class LightHttpLoader extends AsyncTask<UrlReq, byte[], String>{
	private UrlReq req;

	protected String doInBackground(UrlReq...reqs) {
	  int count,i;
		Log.d("LIGHT HTTP LOADER", "IM IN DO IN BACKGROUND");

		req = reqs[0];
		final int id = req.loader_id;
		Log.d("LIGHT HTTP LOADER", "REQUEST CREATED");
		Log.d("LIGHT HTTP LOADER", "I'VE GOT LOADER ID");

		// DEFINE SOME RUNNABLES:
    class DataPusher implements Runnable {
			private byte[] r_data;
			private int idd;
	  	//byte[] r_data =  new byte[] {1, 11, 2, 22, 33, 127};
  		DataPusher(byte[] data, int count, int idz) { 
				// этот код вроде как выполняется в этом потоке (воркер тред)
				idd = idz;
				r_data = new byte[count]; 
	      Log.d("LIGHT HTTP LOADER", "CREATE r_Data for "+count+" bytes");
				System.arraycopy(data, 0, r_data, 0, count);
				//r_data = data;
			}
  		public void run() {
				// а вот этот уже в ui-треде
	      Log.d("LIGHT HTTP LOADER", "START TRANSFER FOR "+r_data.length+" bytes");
	      lightUrlData(idd, r_data);
	      Log.d("LIGHT HTTP LOADER", "I PUSH some DATA TO ML");
  		}
 		}

		InputStream input;
		OutputStream output;
		Log.d("LIGHT HTTP LOADER", "NOW IM GOING INTO TRY SEGMENT");
	try {
	 	URL url_obj = new URL(req.url);
		Log.d("LIGHT HTTP LOADER", "URL CREATED = " + req.url);
	 	HttpURLConnection conexion = (HttpURLConnection) url_obj.openConnection();
		Log.d("LIGHT HTTP LOADER", "CONEXION CREATED");
		// it will change http method to POST
		if (req.method == "POST") {
		  Log.d("LIGHT HTTP LOADER", "METHOD IS POST, SO");
			conexion.setDoOutput(true);
		  Log.d("LIGHT HTTP LOADER", "HTTP MODE CHANGED");
			conexion.setChunkedStreamingMode(0);
		  Log.d("LIGHT HTTP LOADER", "STREAMING MODE CONFIGURED");
	  }		
		// set headers
		i = 0;
		do {
		  Log.d("LIGHT HTTP LOADER", "IM TRYING TO SET HEADERS AND I IS NOW =" + i);
      conexion.setRequestProperty(req.headers[i][0], req.headers[i][1]);
			i++;
		} while(req.headers[i] != null);

		Log.d("LIGHT HTTP LOADER", "HEADERS CREATED");
		// write post data
		if (req.method == "POST") {
      OutputStreamWriter wr = new OutputStreamWriter(conexion.getOutputStream());
		  Log.d("LIGHT HTTP LOADER", "IT's a POST, so OutputStreamWriter created");
      wr.write(req.data);
		  Log.d("LIGHT HTTP LOADER", "DATA WRITED");
      wr.close();
		}
	
		// create input stream
		input = new BufferedInputStream(conexion.getInputStream());
		Log.d("LIGHT HTTP LOADER", "INPUT STREAM CREATED");
    
		// READ RESPONSE HEADERS
		final int totalBytes = conexion.getContentLength();
		Log.d("LIGHT HTTP LOADER", "IVE GOT CONTENT LENGTH " + totalBytes);
		final int httpCode = conexion.getResponseCode();
		Log.d("LIGHT HTTP LOADER", "IVE GOT RESPONSE CODE " + httpCode);
		final String contentType = conexion.getContentType();
		Log.d("LIGHT HTTP LOADER", "IVE GOT CONTENT TYPE " + contentType);
		//call ml
		req.mainthread.post(new Runnable() {
			@Override
			public void run() {
		    Log.d("LIGHT HTTP LOADER", "I PUSH RESPONSE HEADERS TO ML");
	      lightUrlResponse(id, httpCode, contentType, totalBytes);
			}
		});

    // READ DATA FROM INPUT STREAM AND PUSH IT TO OCAML
    byte[] raw_data = new byte[20480];
		Log.d("LIGHT HTTP LOADER", "I'M READY TO READ DATA FROM STREAM");
    long total = 0;
    while ((count = input.read(raw_data)) != -1) {
			// send recieved data to ml
		  Log.d("LIGHT HTTP LOADER", "IT'S RAW DATA:" + raw_data);
  		req.mainthread.post(new DataPusher(raw_data.clone(), count, id)); // вызов того метода который выкидывает ошибку, передаю ему клон массива с данными, внутри тоже все данные дублируются, не понимаю какие данные используются одновременно из нескольких потоков.
		}
 	  input.close();

		// PUSH COMPLETE REQUEST 
		req.mainthread.post(new Runnable() {
  			@Override
  			public void run() {
		      lightUrlComplete(id);
  			}
  	});

	} catch (MalformedURLException e) { Log.d("LIGHT HTTP LOADER", "Malformed URL" + e); }
	  catch (IOException e) { Log.d("LIGHT HTTP LOADER", "IO EXCEPTION" + e); }
	return "Well done";
}

	protected void onProgressUpdate(final byte[] data){
 	}

	protected void onPostExecute(String result) {
  }


  private native void lightUrlResponse(int loader, int httpCode, String contentType, int totalBytes);
	private native void lightUrlData(int loader, byte[] data);
	private native void lightUrlFailed(int loader, int error_code, String error_message);
	private native void lightUrlComplete(int loader);


} 

