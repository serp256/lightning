package ru.redspell.lightning;

import com.google.android.gms.games.GamesClient;
import com.google.android.gms.common.GooglePlayServicesClient;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.games.Player;
import android.content.IntentSender;
import android.os.Bundle;
import android.content.Intent;

import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.IUiLifecycleHelper;
import 	com.google.android.gms.games.GamesActivityResultCodes;




public class LightGameCenter implements GooglePlayServicesClient.ConnectionCallbacks,GooglePlayServicesClient.OnConnectionFailedListener {

	private GamesClient mGamesClient;

	public LightGameCenter() {
		Log.d("LIGHTNING","LightGameCenter");
		GamesClient.Builder builder = new GamesClient.Builder(LightActivity.instance,this,this);
		mGamesClient = builder.create ();
		mGamesClient.setViewForPopups(LightActivity.instance.viewGrp);
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.d("LIGHTNING","Game client call connect");
				mGamesClient.connect();
			};
		});
	}

	private class ConnectionSuccessCallbackRunnable implements Runnable {
		native public void run();
	}

	private class ConnectionFailedCallbackRunnable implements Runnable {
		native public void run();
	}

	private class ConnectionDisconnectCallbackRunnable implements Runnable {
		native public void run();
	}

	public void onConnected(Bundle connectionHint) {
		Log.d("LIGHTNING","Connection onConnected");
		LightActivity.instance.lightView.queueEvent(new ConnectionSuccessCallbackRunnable());
	};

	public void onDisconnected() {
		Log.d("LIGHTNING","onDisconnected");
	};

	private static int INTENT_REQUEST = 912345678;

	public void onConnectionFailed (ConnectionResult result) {
		Log.d("LIGHTNING","onConnectionFailed: " + result.toString());
		if (!result.isSuccess()) {
			if (result.hasResolution()) {
				IUiLifecycleHelper helper = new IUiLifecycleHelper() {
					@Override
					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						if (requestCode == INTENT_REQUEST) {
							LightActivity.instance.removeUiLifecycleHelper(this);
							Log.d("LIGHTNING","Result code is: " + resultCode);
							if (resultCode ==	android.app.Activity.RESULT_OK) 
								mGamesClient.connect ();
							else if (resultCode == GamesActivityResultCodes.RESULT_RECONNECT_REQUIRED)
								mGamesClient.reconnect ();
							else {
								Log.d("LIGHTNING","GameCenter result code not success");
								LightActivity.instance.lightView.queueEvent(new ConnectionFailedCallbackRunnable());
							}
						}
					}
					@Override public void onDestroy() {};
					@Override public void onStop() {};
					@Override public void onPause() {};
					@Override public void onResume() {};
					@Override public void onCreate(Bundle b) {};
					@Override public void onSaveInstanceState(Bundle b) {};
				};
				LightActivity.instance.addUiLifecycleHelper(helper);
				try {
					result.startResolutionForResult(LightActivity.instance,INTENT_REQUEST);
				} catch (android.content.IntentSender.SendIntentException e) {
					Log.d("LIGHTNING","GameCenter send intent exception"); 
					LightActivity.instance.lightView.queueEvent(new ConnectionFailedCallbackRunnable());
				};
			} else LightActivity.instance.lightView.queueEvent(new ConnectionFailedCallbackRunnable());
		}
	}

	public String getPlayerID() {
		if (mGamesClient == null || !mGamesClient.isConnected()) return null;
		else return mGamesClient.getCurrentPlayerId();
	}

	public Player currentPlayer() {
		if (mGamesClient == null) return null;
		if (!mGamesClient.isConnected()) return null;
		return mGamesClient.getCurrentPlayer();
	}

	public void unlockAchievement(final String achievement_id) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				mGamesClient.unlockAchievement(achievement_id);
			}
		});
	}


	private static int SHOW_ACHIEVEMENT_REQUEST = 912345679;

	public void showAchievements() {
		if (mGamesClient == null) return;
		if (!mGamesClient.isConnected()) return;
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override 
			public void run() {
				IUiLifecycleHelper helper = new IUiLifecycleHelper() {
					@Override
					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						if (requestCode == SHOW_ACHIEVEMENT_REQUEST) {
							LightActivity.instance.removeUiLifecycleHelper(this);
							Log.d("LIGHTNING","Result code is: " + resultCode);
							if (resultCode == GamesActivityResultCodes.RESULT_RECONNECT_REQUIRED) mGamesClient.reconnect ();
						}
					}
					@Override public void onDestroy() {};
					@Override public void onStop() {};
					@Override public void onPause() {};
					@Override public void onResume() {};
					@Override public void onCreate(Bundle b) {};
					@Override public void onSaveInstanceState(Bundle b) {};
				};
				LightActivity.instance.addUiLifecycleHelper(helper);
				Intent intent = mGamesClient.getAchievementsIntent();
				LightActivity.instance.startActivityForResult(intent,SHOW_ACHIEVEMENT_REQUEST);
			}
		});
	}



	/*
	private class PlayerLoadListener implements OnPlayersLoadedListener {

		private int ml_callback;
		native private void call_success_ml(String name);
		native private void call_fail_ml(String name);

		public void onPlayersLoaded(int statusCode,PlayerBuffer buffer) {
			switch statusCode {
				case GamesClient.STATUS_OK: 
					if (playerBuffer.
					Player 
					break;
				case GamesClient.STATUS_CLIENT_RECONNECT_REQUIRED:
					break;
				default: break;
			};
		}
	};

	public void loadPlayer(String player_id) {
		if (mGamesClient != null) 
			LightActivity.instance.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					mGamesClient.loadPlayer();
				}
			});
	}
	*/

	public void signOut() {
		if (mGamesClient != null) 
			LightActivity.instance.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					mGamesClient.signOut();
				}
			});
	}


};
