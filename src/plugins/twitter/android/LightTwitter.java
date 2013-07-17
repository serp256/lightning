package ru.redspell.lightning.plugins;

import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.Queue;
import java.util.LinkedList;

import twitter4j.AsyncTwitterFactory;
import twitter4j.AsyncTwitter;
import twitter4j.TwitterAdapter;
import twitter4j.TwitterException;
import twitter4j.TwitterMethod;
import twitter4j.Status;

import twitter4j.auth.RequestToken;
import twitter4j.auth.AccessToken;

import ru.redspell.lightning.OAuth;
import ru.redspell.lightning.OAuthDialog.UrlRunnable;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.LightView;
import ru.redspell.lightning.utils.Log;

import android.content.Context;
import android.content.SharedPreferences;

public class LightTwitter {
	private static final String SHARED_PREFS_NAME = "light_twitter";
	private static final String SHARED_PREFS_TOKEN = "token";
	private static final String SHARED_PREFS_SECRET = "secret";

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
	private static boolean hasAccessToken = false;
	private static String pendingStatus = null;
	private static LinkedList<Callbacks> callbackQueue = new LinkedList<Callbacks>();

	public static void init(String consumerKey, String consumerSecret) {
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

				if (pendingStatus != null) {
					twitter.updateStatus(pendingStatus);
					pendingStatus = null;
				}
			}

			@Override
			public void updatedStatus(Status status) {
				Log.d("LIGHTNING", "status updated");

				Callbacks cbs = callbackQueue.remove();
				cbs.success();
				cbs.free();
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
					Callbacks cbs = callbackQueue.remove();
					cbs.fail(reason);
					cbs.free();
				}
			}
		});		
	}

	public static void tweet(String text, int success, int fail) {
		Log.d("LIGHTNING", "tweet " + (new Integer(success)).toString() + " " + (new Integer(fail)).toString());

		Callbacks cbs = new Callbacks(success, fail);

		if (twitter == null) {
			cbs.fail("twitter not initialized");
			cbs.free();
			return;
		}

		callbackQueue.add(cbs);

		if (!hasAccessToken) {
			SharedPreferences shrdPrefs = LightActivity.instance.getApplicationContext().getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE);

			if (shrdPrefs.contains(SHARED_PREFS_TOKEN) && shrdPrefs.contains(SHARED_PREFS_SECRET)) {
				hasAccessToken = true;
				twitter.setOAuthAccessToken(new AccessToken(shrdPrefs.getString(SHARED_PREFS_TOKEN, ""), shrdPrefs.getString(SHARED_PREFS_SECRET, "")));
				twitter.updateStatus(new String(text)); //passing new String(text) as parameter cause if passing directly text it leads to strange segfault on some devices
			} else {
		 		pendingStatus = new String(text);
				twitter.getOAuthRequestTokenAsync("http://twitter.redspell.ru/access_token/ok");				
			}
		} else {
			twitter.updateStatus(new String(text));
		}
	}
}