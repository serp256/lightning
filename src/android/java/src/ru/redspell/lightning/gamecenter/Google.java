package ru.redspell.lightning.gamecenter;

import com.google.android.gms.games.GamesClient;
import com.google.android.gms.common.GooglePlayServicesClient;
import com.google.android.gms.common.ConnectionResult;
// import com.google.android.gms.games.Player;
import android.content.IntentSender;
import android.os.Bundle;
import android.content.Intent;

import ru.redspell.lightning.utils.Log;

import ru.redspell.lightning.IUiLifecycleHelper;
import com.google.android.gms.games.GamesActivityResultCodes;


import ru.redspell.lightning.Lightning;

public class Google implements GameCenter,GooglePlayServicesClient.ConnectionCallbacks,GooglePlayServicesClient.OnConnectionFailedListener {

	private GamesClient mGamesClient;
	
	private ConnectionListener listener;

    private Player player;
    
    /*
     * 
     */
	public Google() {
	    this(null);
	}


    /*
     * 
     */
    public Google(ConnectionListener l) {
		Log.d("LIGHTNING","");
		GamesClient.Builder builder = new GamesClient.Builder(Lightning.activity,this,this);
		mGamesClient = builder.create ();
		mGamesClient.setViewForPopups(Lightning.activity.viewGrp);
		listener = l;
		Log.d("ok");
    }


    /*
     * setConnectionListener
     */
    @Override
    public void setConnectionListener(ConnectionListener l) {
        listener = l;
    }


    /*
     * connect
     */
    @Override
    public void connect() {
		Lightning.activity.runOnUiThread(new Runnable() {
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
							Lightning.activity.removeUiLifecycleHelper(this);
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
				Lightning.activity.addUiLifecycleHelper(helper);
				try {
					result.startResolutionForResult(Lightning.activity,INTENT_REQUEST);
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
		    return mGamesClient.getCurrentPlayerId();
		}   
	}


    @Override
    public Player currentPlayer() {
		if (mGamesClient == null) return null;
		if (!mGamesClient.isConnected()) return null;
		
		if (player == null) {
		    player = new Player() {
		        @Override
		        public String getPlayerId() {
		          return mGamesClient.getCurrentPlayerId();
		        }
		        
		        @Override
		        public String getDisplayName() {
		          return mGamesClient.getCurrentPlayer().getDisplayName();
		        }
		    };
		}
		
		return player;
	}

	
	@Override
	public void submitScore(final String leaderboard_id, final long score) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.d ("LIGHTNING.GameCenterAndroid", String.format("value = %d", score));
				mGamesClient.submitScore(leaderboard_id, score);
			}
		});
	}



    @Override
	public void unlockAchievement(final String achievement_id) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				mGamesClient.unlockAchievement(achievement_id);
			}
		});
	}


	private static int SHOW_ACHIEVEMENT_REQUEST = 912345679;
	private static int SHOW_LEADERBOARD_REQUEST = 912345680;


	public void showAchievements() {
		if (mGamesClient == null) return;
		if (!mGamesClient.isConnected()) return;
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override 
			public void run() {
				IUiLifecycleHelper helper = new IUiLifecycleHelper() {
					@Override
					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						if (requestCode == SHOW_ACHIEVEMENT_REQUEST) {
							Lightning.activity.removeUiLifecycleHelper(this);
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
				Lightning.activity.addUiLifecycleHelper(helper);
				Intent intent = mGamesClient.getAchievementsIntent();
				Lightning.activity.startActivityForResult(intent,SHOW_ACHIEVEMENT_REQUEST);
			}
		});
	}

	public void showLeaderboard(final String boardId) {
		if (mGamesClient == null) return;
		if (!mGamesClient.isConnected()) return;
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override 
			public void run() {
				IUiLifecycleHelper helper = new IUiLifecycleHelper() {
					@Override
					public void onActivityResult(int requestCode, int resultCode, Intent data) {
						if (requestCode == SHOW_LEADERBOARD_REQUEST) {
							Lightning.activity.removeUiLifecycleHelper(this);
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
				Lightning.activity.addUiLifecycleHelper(helper);
				Intent intent = mGamesClient.getLeaderboardIntent(boardId);
				Lightning.activity.startActivityForResult(intent,SHOW_LEADERBOARD_REQUEST);
			}
		});
	}

	public void signOut() {
		if (mGamesClient != null) 
			Lightning.activity.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					mGamesClient.signOut();
				}
			});
	}



  

};
