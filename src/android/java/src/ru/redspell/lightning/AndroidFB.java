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

	public static boolean check_auth_token () {
		return fb.isSessionValid ();
	}

	public static void init (String app_id) {
	 	Log.d("LIGHTNING", "Init FB " + app_id);
		fb = new Facebook(app_id);
	}

	public static native void successAuthorize ();
	public static native void errorAuthorize ();

	public static void authorize (final String [] permissions)  {
	  Log.d("LIGHTNING", "authorize with actibity" + LightView.instance.toString ()	);
		String permList = "PERSMISSIONS : \n";
		for (String str : permissions) {
			permList = permList + str + "\n";
		}
	  Log.d("LIGHTNING", permList );

		LightView.instance.post (new Runnable () {
			public void run () {
				fb.authorize(LightView.instance.activity, permissions,  new DialogListener() {
						 @Override
						 public void onComplete(Bundle values) {
							 Log.d("LIGHTNING", "onCOMPLETE"); 
							 accessToken = values.getString(Facebook.TOKEN);
								LightView.instance.queueEvent (new Runnable () {
									public void run () {
										successAuthorize();
									}
								});
							 Log.d("LIGHTNING", "authToken="+accessToken); 
						 }

						 @Override
						 public void onFacebookError(FacebookError error) { 
							 Log.d("LIGHTNING","fb_error:" + error.toString ());
								LightView.instance.queueEvent (new Runnable () {
									public void run () {
										errorAuthorize();
									}
								});
						 }

						 @Override
						 public void onError(DialogError e) { 
							 Log.d("LIGHTNING", "error" + e.toString ());
								LightView.instance.queueEvent (new Runnable () {
									public void run () {
										errorAuthorize();
									}
								});
						 }

						 @Override
						 public void onCancel() {
							 Log.d("LIGHTNING", "onCANCEL");
								LightView.instance.queueEvent (new Runnable () {
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
		LightView.instance.post (new Runnable () {
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
								LightView.instance.queueEvent (new Runnable () {
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
								LightView.instance.queueEvent (new Runnable () {
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
								LightView.instance.queueEvent (new Runnable () {
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
								LightView.instance.queueEvent (new Runnable () {
									public void run () {
										errorGraphAPI(error);
									}
								});
						}

						@Override
						public void onComplete(String response, Object state) {
								Log.d("LIGHTTEST", "RESPONES" + response);
								final String resp =  response;
								LightView.instance.queueEvent (new Runnable () {
									public void run () {
										successGraphAPI(resp);
									}
								});
						}
				}, null);
			}
		});
	}

	private static class AppRequestDelegateRunnable implements Runnable {
		private int _delegate;
		private int _recordFieldNum;
		private String _param;

		public AppRequestDelegateRunnable(int delegate, int recordFieldNum, String param) {
			_delegate = delegate;
			_recordFieldNum = recordFieldNum;
			_param = param;
		}

		public native void run();
	}

	private static class AppRequestDialogListener implements DialogListener {
		private int _delegate;

		public AppRequestDialogListener(int delegate) {
			_delegate = delegate;
		}

		public void onCancel() {
			Log.d("LIGHTNING", "AppRequestDialogListener onCancel");
			LightView.instance.queueEvent(new AppRequestDelegateRunnable(_delegate, 1, null));
		}

		public void onComplete(Bundle values) {
			Log.d("LIGHTNING", "AppRequestDialogListener onComplete");
			LightView.instance.queueEvent(new AppRequestDelegateRunnable(_delegate, 0, null));
		}

		public void onError(DialogError de) {
			Log.d("LIGHTNING", "AppRequestDialogListener onError");
			LightView.instance.queueEvent(new AppRequestDelegateRunnable(_delegate, 2, de.getMessage()));
		}

		public void onFacebookError(FacebookError fbe) {
			Log.d("LIGHTNING", "AppRequestDialogListener onError");
			LightView.instance.queueEvent(new AppRequestDelegateRunnable(_delegate, 2, fbe.getMessage()));
		}
	}

	public static void showAppRequestDialog(final String mes, final String recipients, final String filter, final String title, final int delegate) {
		LightView.instance.post(new Runnable() {
			@Override
			public void run() {
				Bundle params = new Bundle();

				params.putString("to", recipients);
				params.putString("message", mes);
				params.putString("filter", filter);
				params.putString("title", title);

				Log.d("LIGHTNING", recipients + " " +  mes + " " +  filter + " " +  title);

				fb.dialog(LightView.instance.getContext(), "apprequests", params, new AppRequestDialogListener(delegate));
			}
		});
	}
}