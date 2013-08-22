package ru.redspell.lightning.plugins;

import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.Queue;
import java.util.LinkedList;
import java.io.File;
import java.lang.Exception;

import twitter4j.AsyncTwitterFactory;
import twitter4j.AsyncTwitter;
import twitter4j.TwitterAdapter;
import twitter4j.TwitterException;
import twitter4j.TwitterMethod;
import twitter4j.Status;

import twitter4j.auth.RequestToken;
import twitter4j.auth.AccessToken;

import twitter4j.media.ImageUploadFactory;
import twitter4j.media.ImageUpload;

import twitter4j.conf.Configuration;
import twitter4j.conf.ConfigurationBuilder;

import ru.redspell.lightning.OAuth;
import ru.redspell.lightning.OAuthDialog.UrlRunnable;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.LightView;
import ru.redspell.lightning.utils.Log;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.AsyncTask;

public class LightTwitter extends LightIntentPlugin {
	private static final String SHARED_PREFS_NAME = "light_twitter";
	private static final String SHARED_PREFS_TOKEN = "token";
	private static final String SHARED_PREFS_SECRET = "secret";

	private static LightTwitter instance;

	private static LightTwitter getInstance() {
		if (instance == null) {
			instance = new LightTwitter();
		}

		return instance;
	}

	private static class Callbacks {
		private int _success;
		private int _fail;

		public Callbacks(int success, int fail) {
			_success = success;
			_fail = fail;
		}

		private native void nativeSuccess(int cb);
		private native void nativeFail(int cb, String reason);
		private native void nativeFree(int success, int fail);

		public void success() {
			Log.d("LIGHTNING", "callbacks success call " + (new Integer(_success)).toString());
			if (_success > 0) {
				LightView.instance.queueEvent(new Runnable() { @Override public void run() { nativeSuccess(_success); } });	
			}
		}

		public void fail(final String reason) {
			if (_fail > 0) {
				LightView.instance.queueEvent(new Runnable() { @Override public void run() { nativeFail(_fail, new String(reason)); }});
			}
		}

		public void free() {
			if (_success > 0 || _fail > 0) {
				LightView.instance.queueEvent(new Runnable() { @Override public void run() { nativeFree(_success, _fail); }});	
			}
		}
	}

	private static AsyncTwitter twitter;
	private static String consumerKey;
	private static String consumerSecret;
	private static boolean hasAccessToken = false;
	private static Runnable pendingRequest = null;
	private static LinkedList<Callbacks> callbackQueue = new LinkedList<Callbacks>();

	private static void success(Callbacks cbs) {
		cbs.success();
		cbs.free();
	}

	private static void success() {
		success(callbackQueue.remove());
	}

	private static void fail(Callbacks cbs, String reason) {
		cbs.fail(reason);
		cbs.free();
	}

	private static void fail(String reason) {
		fail(callbackQueue.remove(), reason);
	}

	public static void init(String _consumerKey, String _consumerSecret) {
		consumerKey = _consumerKey;
		consumerSecret = _consumerSecret;

		twitter = AsyncTwitterFactory.getSingleton();
		twitter.setOAuthConsumer(consumerKey, consumerSecret);
		twitter.addListener(new TwitterAdapter() {
			@Override
			public void gotOAuthRequestToken(final RequestToken token) {
				final UrlRunnable redirectHandler = new UrlRunnable() {
					@Override
					public void run(String urlStr) {
						try {
			                Matcher m = Pattern.compile(".*oauth_verifier=([^&]+).*").matcher((new java.net.URL(urlStr)).getQuery());

			                if (m.matches()) {
			                	twitter.getOAuthAccessTokenAsync(token, m.group(1));
			                }
						} catch (java.net.MalformedURLException e) {
							Log.d("LIGHTNING", "java.net.MalformedURLException " + e.getMessage());
						}					
					}
				};

				OAuth.dialog(token.getAuthorizationURL(), null, redirectHandler, "/access_token/ok");
			}

			@Override
			public void gotOAuthAccessToken(AccessToken token) {
				Log.d("LIGHTNING", "gotOAuthAccessToken call");

				SharedPreferences shrdPrefs = LightActivity.instance.getApplicationContext().getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE);
				SharedPreferences.Editor editor = shrdPrefs.edit();
				editor.putString(SHARED_PREFS_TOKEN, token.getToken());
				editor.putString(SHARED_PREFS_SECRET, token.getTokenSecret());
				editor.apply();
				hasAccessToken = true;

				if (pendingRequest != null) {
					pendingRequest.run();
					pendingRequest = null;
/*					twitter.updateStatus(pendingStatus);
					pendingStatus = null;*/
				}
			}

			@Override
			public void updatedStatus(Status status) {
				Log.d("LIGHTNING", "status updated");
				success();
			}

			@Override
			public void onException(TwitterException te, TwitterMethod method) {
				Log.d("LIGHTNING", "onException");

				String reason = null;
				switch (method) {
					case OAUTH_ACCESS_TOKEN:
						reason = "error when retrieving access token: " + te.getMessage();
						break;

					case OAUTH_REQUEST_TOKEN:
						reason = "error when retrieving request token: " + te.getMessage();
						break;

					case UPDATE_STATUS:
						reason = "error when updating status: " + te.getMessage();
						break;
				}

				if (reason != null) {
					fail(reason);
				}
			}
		});		
	}

	private static void requestAccessToken(Runnable request) {
		SharedPreferences shrdPrefs = LightActivity.instance.getApplicationContext().getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE);

		if (shrdPrefs.contains(SHARED_PREFS_TOKEN) && shrdPrefs.contains(SHARED_PREFS_SECRET)) {
			hasAccessToken = true;
			twitter.setOAuthAccessToken(new AccessToken(shrdPrefs.getString(SHARED_PREFS_TOKEN, ""), shrdPrefs.getString(SHARED_PREFS_SECRET, "")));			
			request.run();
		} else {
	 		pendingRequest = request;
			twitter.getOAuthRequestTokenAsync("http://twitter.redspell.ru/access_token/ok");				
		}
	}

	private static Callbacks checkTwitterInstance(int success, int fail) {
		Callbacks cbs = new Callbacks(success, fail);
		if (twitter == null) {
			fail(cbs, "twitter not initialized");
			return null;
		}

		return cbs;
	}

	private static void runRequest(Runnable request, int success, int fail) {
		Callbacks cbs;

		if ((cbs = checkTwitterInstance(success, fail)) != null) {
			callbackQueue.add(cbs);

			if (!hasAccessToken) {
				requestAccessToken(request);
			} else {
				request.run();
			}			
		}
	}	

	public static void tweet(final String text, int success, int fail) {
		Log.d("LIGHTNING", "tweet " + (new Integer(success)).toString() + " " + (new Integer(fail)).toString());

		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("text/plain");
		intent.setPackage("com.twitter.android");
		intent.putExtra(Intent.EXTRA_TEXT, text);
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

		if (getInstance().sendIntent("com.twitter.android", intent)) {
			Callbacks cbs = new Callbacks(success, fail);
			cbs.success ();
			cbs.free ();

			return;
		}

		runRequest(new Runnable() {
			@Override public void run() {
				twitter.updateStatus(new String(text)); //passing new String(text) as parameter cause if passing directly text it leads to strange segfault on some devices
			}
		}, success, fail);		
	}

	private static ImageUpload upload;
	private static ImageUpload uploadInstance() throws Exception, TwitterException {
		if (upload == null) {
			if (twitter == null) {
				throw new Exception("initialize twitter before getting upload instance");
			}

			AccessToken token = twitter.getOAuthAccessToken();
			Configuration conf = new ConfigurationBuilder()
			    .setOAuthConsumerKey(consumerKey)
			    .setOAuthConsumerSecret(consumerSecret)
			    .setOAuthAccessToken(token.getToken())
			    .setOAuthAccessTokenSecret(token.getTokenSecret())
			    .build();					

			upload = (new ImageUploadFactory(conf)).getInstance();
		}

		return upload;
	}

	private static class UploadParam {
		public String fname;
		public String text;

		public UploadParam(String fname, String text) {
			this.fname = fname;
			this.text = text;
		}
	}

	private static class UploadTask extends AsyncTask<UploadParam, Void, Exception> {
		protected Exception doInBackground(UploadParam... params) {
			try {
				uploadInstance().upload(new File(params[0].fname), params[0].text);
				return null;
			} catch (Exception e) {
				return e;
			}
		}

		protected void onPostExecute(Exception result) {
		 	if (result != null) {
		 		fail(result.getMessage());
		 	} else {
		 		success();
		 	}
		}
	 }

	public static void tweetPic(int success, int fail, final String fname, final String text) {
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("image/*");
		intent.setPackage("com.twitter.android");
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		intent.putExtra(Intent.EXTRA_TEXT, text);
		intent.putExtra(Intent.EXTRA_STREAM, android.net.Uri.parse("file://" + fname));

		if (getInstance().sendIntent("com.twitter.android", intent)) {
			Callbacks cbs = new Callbacks(success, fail);
			cbs.success ();
			cbs.free ();

			return;			
		}

		runRequest(new Runnable() {
			@Override
			public void run() {
				(new UploadTask()).execute(new UploadParam(fname, text));
			}
		}, success, fail);
	}
}
