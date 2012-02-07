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
		req = reqs[0];
		final int id = req.loader_id;

		// DEFINE SOME RUNNABLES:
		class DataPusher implements Runnable {
			private byte[] r_data;
			private int idd;
			DataPusher(byte[] data, int count, int idz) { 
				// этот код вроде как выполняется в этом потоке (воркер тред)
				idd = idz;
				r_data = new byte[count]; 
				System.arraycopy(data, 0, r_data, 0, count);
			}
			public void run() {
				// а вот этот уже в rendered!!!! -треде, не в UI
				lightUrlData(idd, r_data);
			}
		}


		InputStream input;
		OutputStream output;
		try {
			URL url_obj = new URL(req.url);
			HttpURLConnection conexion = (HttpURLConnection) url_obj.openConnection();
			conexion.setDoOutput(true);
			
			// set headers
			i = 0;
			boolean hasContentLengthHeader = false;
			while(req.headers[i] != null) {
				conexion.setRequestProperty(req.headers[i][0], req.headers[i][1]);
				if (req.headers[i][0].toLowerCase().equals("content-length")) {
				  hasContentLengthHeader = true;
				}
				i++;
			} 

			try {
			  if (req.method.equals("POST")) {
			    if (!hasContentLengthHeader) {
			      conexion.setRequestProperty("Content-Length", String.valueOf(req.data.length)); 
			    }  
			  
			  	conexion.getOutputStream().write(req.data);
			  	conexion.getOutputStream().close();
			  } else {
  			    conexion.connect();
			  }
			} catch (Exception e) {
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

		
			final int totalBytes = conexion.getContentLength();
			final int httpCode = conexion.getResponseCode();
			final String contentType = conexion.getContentType();
			
            Log.d("LIGHT HTTP LOADER", "Got response - code: " + httpCode + " content-type: " + contentType + " length: " + totalBytes);
            
            // сообщаем, что получили ответ от сервера
            req.surface_view.queueEvent(
              new Runnable() {
			    @Override
			    public void run() {
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

