package ru.redspell.lightning;

import android.os.AsyncTask;
import java.net.URL;
import java.net.HttpURLConnection;
import java.io.OutputStreamWriter;
import java.io.*;
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
			DataPusher(byte[] data, int count, int idz) { 
				// этот код вроде как выполняется в этом потоке (воркер тред)
				idd = idz;
				r_data = new byte[count]; 
				Log.d("LIGHT HTTP LOADER", "CREATE r_Data for "+count+" bytes");
				System.arraycopy(data, 0, r_data, 0, count);
			}
			public void run() {
				// а вот этот уже в rendered!!!! -треде, не в UI
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

    	    conexion.setRequestMethod(req.method);
			conexion.setDoOutput(true);
			conexion.setChunkedStreamingMode(0);
			
			// set headers
			i = 0;
			while(req.headers[i] != null) {
				Log.d("LIGHT HTTP LOADER", "IM TRYING TO SET HEADERS AND I IS NOW =" + i);
				conexion.setRequestProperty(req.headers[i][0], req.headers[i][1]);
				i++;
			} 

			Log.d("LIGHT HTTP LOADER", "HEADERS CREATED");
			
			//  make request
			try {
			  if (req.method == "POST") {
			  	OutputStreamWriter wr = new OutputStreamWriter(conexion.getOutputStream());
				Log.d("LIGHT HTTP LOADER", "IT's a POST, so OutputStreamWriter created");
				wr.write(req.data);
				Log.d("LIGHT HTTP LOADER", "DATA WRITED");
				wr.close();
			  } else {
  			    conexion.connect();
			  }
			} catch (Exception e) {
			
			  Log.d("LIGHT HTTP LOADER", "HOHOOHhihi: " + e);
			
			  final String msg = e.getMessage();
              req.surface_view.queueEvent(
                new Runnable() {
			      @Override
			      public void run() {
				    lightUrlFailed(id, 599, msg);
			      }
			    }   
			  );
              return "error";
			}

		
			//  READ RESPONSE HEADERS
			final int totalBytes = conexion.getContentLength();
			final int httpCode = conexion.getResponseCode();
			final String contentType = conexion.getContentType();
			
            Log.d("LIGHT HTTP LOADER", "Got response - code: " + httpCode + " content-type: " + contentType + " length: " + totalBytes);
            
            // сообщаем, что получили ответ от сервера
            req.surface_view.queueEvent(
              new Runnable() {
			    @Override
			    public void run() {
			      Log.d("LIGHT HTTP LOADER", "I PUSH RESPONSE HEADERS TO ML");
				  lightUrlResponse(id, httpCode, contentType, totalBytes);
			    }
			  }   
			);


			// пробуем читать данные. если было не 200, то получим ошибку.
			boolean skipReading = false;
			try {
			  input = new BufferedInputStream(conexion.getInputStream());
			} catch (Exception ioe) {
			  conexion.disconnect();
			  skipReading = true;
			  input = null;
			} 

            if (!skipReading) {
			  byte[] raw_data = new byte[30480];
		      while ((count = input.read(raw_data,0,raw_data.length)) != -1) {
			    req.surface_view.queueEvent(new DataPusher(raw_data, count, id)); 
		      }
		      input.close();
		    }

			conexion.disconnect();
            
            req.surface_view.queueEvent(
              new Runnable() {
			    @Override
				public void run() {
				  lightUrlComplete(id);
				}
			  }
			);

		} catch (MalformedURLException e) { 
		  Log.d("LIGHT HTTP LOADER", "Malformed URL" + e); 
		} catch (IOException e) { 
		  Log.d("LIGHT HTTP LOADER", "IO EXCEPTION" + e); 
		} catch (Exception e) {
		  Log.d("LIGHT HTTP LOADER", "EXCEPTION" + e); 
		}
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

