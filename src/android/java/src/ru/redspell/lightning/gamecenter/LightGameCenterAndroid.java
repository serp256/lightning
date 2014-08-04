package ru.redspell.lightning.gamecenter;

import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.games.Games;
import com.google.android.gms.common.GooglePlayServicesClient;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.games.Player;
import android.content.IntentSender;
import android.os.Bundle;
import android.content.Intent;

import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.IUiLifecycleHelper;
import com.google.android.gms.games.GamesActivityResultCodes;




public class LightGameCenterAndroid implements LightGameCenter,GoogleApiClient.ConnectionCallbacks,GoogleApiClient.OnConnectionFailedListener {

	private GoogleApiClient mGamesClient;
	
	private LightGameCenterConnectionListener listener;

    private LightGameCenterPlayer player;
    
    /*
     * LightGameCenter
     */
	public LightGameCenterAndroid() {
	    this(null);
	}


    /*
     * LightGameCenter
     */
	public LightGameCenterAndroid(LightGameCenterConnectionListener l) {
		Log.d("LIGHTNING","LightGameCenter");
		GoogleApiClient.Builder builder = new GoogleApiClient.Builder(LightActivity.instance,this,this);
		builder.setViewForPopups(LightActivity.instance.viewGrp);
		mGamesClient = builder.build ();
		//mGamesClient.setViewForPopups(LightActivity.instance.viewGrp);
		listener = l;
	}


    /*
     * setConnectionListener
     */
    @Override
    public void setConnectionListener(LightGameCenterConnectionListener l) {
        listener = l;
    }


    /*
     * connect
     */
    @Override
    public void connect() {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.d("LIGHTNING","Game client call connect");
				mGamesClient.connect();
			};
		});      
    }



    /*
     *  Connection handlers
     */
	public void onConnected(Bundle connectionHint) {
		Log.d("LIGHTNING","Connection onConnected");
		if (listener != null) {
		    listener.onConnected();
		}
	};

	public void onConnectionSuspended (int cause) {
	};


    /*
     *
     */
	public void onDisconnected() {
		Log.d("LIGHTNING","onDisconnected");
		if (listener != null) {
		    listener.onDisconnected();
		}
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
								if (listener != null) {
								    listener.onConnectFailed();
								}
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
					if (listener != null) {
					    listener.onConnectFailed();
					}
				};
			} else if (listener != null) listener.onConnectFailed();
		}
	}

    @Override
	public String getPlayerID() {
		if (mGamesClient == null || !mGamesClient.isConnected()) return null;
		else {
		    return Games.Players.getCurrentPlayerId(mGamesClient);
		}   
	}


    @Override
    public LightGameCenterPlayer currentPlayer() {
		if (mGamesClient == null) return null;
		if (!mGamesClient.isConnected()) return null;
		
		if (player == null) {
		    player = new LightGameCenterPlayer() {
		        @Override
		        public String getPlayerId() {
		          return Games.Players.getCurrentPlayerId(mGamesClient);
		        }
		        
		        @Override
		        public String getDisplayName() {
		          return Games.Players.getCurrentPlayer(mGamesClient).getDisplayName();
		        }
		    };
		}
		
		return player;
	}

	
	@Override
	public void submitScore(final String leaderboard_id, final long score) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.d ("LIGHTNING.GameCenterAndroid", String.format("value = %d", score));
				Games.Leaderboards.submitScore(mGamesClient,leaderboard_id, score);
			}
		});
	}



    @Override
	public void unlockAchievement(final String achievement_id) {
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Games.Achievements.unlock(mGamesClient,achievement_id);
			}
		});
	}


	private static int SHOW_ACHIEVEMENT_REQUEST = 912345679;
	private static int SHOW_LEADERBOARD_REQUEST = 912345680;


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
				Intent intent = Games.Achievements.getAchievementsIntent(mGamesClient);
				LightActivity.instance.startActivityForResult(intent,SHOW_ACHIEVEMENT_REQUEST);
			}
		});
	}

	public void showLeaderboard(final String boardId) {
		if (mGamesClient == null) return;
		if (!mGamesClient.isConnected()) return;
		LightActivity.instance.runOnUiThread(new Runnable() {
			@Override 
			public void run() {
				IUiLifecycleHelper helper = new IUiLifecycleHelper() {
					@Override
					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						if (requestCode == SHOW_LEADERBOARD_REQUEST) {
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
				Intent intent = Games.Leaderboards.getLeaderboardIntent(mGamesClient,boardId);
				LightActivity.instance.startActivityForResult(intent,SHOW_LEADERBOARD_REQUEST);
			}
		});
	}

	public void signOut() {
		if (mGamesClient != null) 
			LightActivity.instance.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					mGamesClient.disconnect();
				}
			});
	}



  

};
