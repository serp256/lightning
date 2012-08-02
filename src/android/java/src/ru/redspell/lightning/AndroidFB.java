package ru.redspell.lightning;

import android.content.Intent;
import com.facebook.android.*;
import com.facebook.android.Facebook.*;
import com.facebook.android.AsyncFacebookRunner.*;

import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.io.IOException;
import android.util.Log;
import android.os.Bundle;
import android.app.Activity;
import ru.redspell.lightning.LightView;


public class AndroidFB {
	public static Facebook fb = null;
	private int onCompleteAuth;
	private static String accessToken = "";
	private static LightView view =null;


	public static boolean check_auth_token () {
		return fb.isSessionValid ();
	}

	public static void init (String app_id) {
	  Log.d("LIGHTNING", "Init FB " + app_id);
		fb = new Facebook(app_id);
	}

	public static void setView (LightView _view) {
		view = _view;
	}

	public static native void successAuthorize ();
	public static native void errorAuthorize ();

	public static void authorize (final String [] permissions)  {
	  Log.d("LIGHTNING", "authorize with actibity" + view.toString ()	);
		String permList = "PERSMISSIONS : \n";
		for (String str : permissions) {
			permList = permList + str + "\n";
		}
	  Log.d("LIGHTNING", permList );

		view.post (new Runnable () {
			public void run () {
				fb.authorize(view.activity, permissions,  new DialogListener() {
						 @Override
						 public void onComplete(Bundle values) {
							 Log.d("LIGHTNING", "onCOMPLETE"); 
							 accessToken = values.getString(Facebook.TOKEN);
								view.queueEvent (new Runnable () {
									public void run () {
										successAuthorize();
									}
								});
							 Log.d("LIGHTNING", "authToken="+accessToken); 
						 }

						 @Override
						 public void onFacebookError(FacebookError error) { 
							 Log.d("LIGHTNING","fb_error:" + error.toString ());
								view.queueEvent (new Runnable () {
									public void run () {
										errorAuthorize();
									}
								});
						 }

						 @Override
						 public void onError(DialogError e) { 
							 Log.d("LIGHTNING", "error" + e.toString ());
								view.queueEvent (new Runnable () {
									public void run () {
										errorAuthorize();
									}
								});
						 }

						 @Override
						 public void onCancel() {
							 Log.d("LIGHTNING", "onCANCEL");
								view.queueEvent (new Runnable () {
									public void run () {
										errorAuthorize();
									}
								});
						 }
				 });
			}
		});
	}

	public static native void successGraphAPI (String response);
	public static native void errorGraphAPI (String error);

	public static void graphAPI(final String path,final String [][] graph_params){
		Log.d("LIGHTTEST", "\n\n\n\n\n\ngraphAPI ");
		view.post (new Runnable () {
			public void run () {
				Log.d("LIGHTTEST", "=========================================");
				Bundle params = new Bundle();
				Log.d("LIGHTTEST", "new Bundle");
				params.putString(Facebook.TOKEN,accessToken);
				Log.d("LIGHTTEST", "put string");
				Bundle prms = params;
				Log.d("LIGHTTEST","acces_token="+accessToken);
				String str = "GRAH PARAMS : ";
				for (String[] param : graph_params) {
					params.putString(param[0],param[1]);
					str = str +  param[0] + "=" + param[1] + "; ";
				}
				Log.d("LIGHTTEST",str);

				AsyncFacebookRunner mAsyncRunner = new AsyncFacebookRunner(fb);

				mAsyncRunner.request(path, prms,  new RequestListener() {

						@Override
						public void onMalformedURLException(MalformedURLException e, Object state) {
								// TODO Auto-generated method stub
								final String error =  "MALFORMED EXCEPTION " + e.toString ();
								Log.d("LIGHTTEST", error);
								view.queueEvent (new Runnable () {
									public void run () {
										errorGraphAPI(error);
									}
								});
						}

						@Override
						public void onIOException(IOException e, Object state) {
								// TODO Auto-generated method stub
								final String error =  "IO EXCEPTION " + e.toString ();
								Log.d("LIGHTTEST", error);
								view.queueEvent (new Runnable () {
									public void run () {
										errorGraphAPI(error);
									}
								});
						}

						@Override
						public void onFileNotFoundException(FileNotFoundException e, Object state) {
								// TODO Auto-generated method stub
								final String error =  "FILE NOT FOUND EXCEPTION " + e.toString ();
								Log.d("LIGHTTEST", error);
								view.queueEvent (new Runnable () {
									public void run () {
										errorGraphAPI(error);
									}
								});

						}

						@Override
						public void onFacebookError(FacebookError e, Object state) {
								// TODO Auto-generated method stub

								final String error =  "FACEBOOK EXCEPTION " + e.toString ();
								Log.d("LIGHTTEST", error);
								view.queueEvent (new Runnable () {
									public void run () {
										errorGraphAPI(error);
									}
								});
						}

						@Override
						public void onComplete(String response, Object state) {
								Log.d("LIGHTTEST", "RESPONES" + response);
								final String resp =  response;
								view.queueEvent (new Runnable () {
									public void run () {
										successGraphAPI(resp);
									}
								});
						}
				}, null);
			}
		});
	}


}
