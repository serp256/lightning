package ru.redspell.lightning.gamecenter;

import com.amazon.ags.api.*;
import com.amazon.ags.api.AmazonGamesStatus;
import com.amazon.ags.api.profiles.*;

import com.amazon.ags.api.leaderboards.*; 
import com.amazon.ags.api.overlay.*;
import com.amazon.ags.api.profiles.*;
import com.amazon.ags.api.whispersync.*;
import com.amazon.ags.api.whispersync.migration.*;
import com.amazon.ags.api.whispersync.model.*;
import com.amazon.ags.api.achievements.*;
//import com.amazon.ags.api.profiles;

import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.IUiLifecycleHelper;

import java.util.EnumSet;
import java.lang.Enum;

import ru.redspell.lightning.v2.Lightning;

public class Amazon implements GameCenter,AmazonGamesCallback {

	private AmazonGamesClient amzGamesClient;
	
	private ConnectionListener listener;
	
	private Player player = null;
    

    /*
     * Amazon
     */
	public Amazon() {
	    this(null);
	}


    /*
     * Amazon
     */
    public Amazon(ConnectionListener l) {
		listener = l;
    }


    /*
     * setConnectionListener
     */
    public void setConnectionListener(ConnectionListener l) {
        listener = l;
    }


    /*
     * connect
     */
    public void connect() {
        
		final Amazon me = this;

		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.d("LIGHTNING","Amazon Games Client call initialize 1");
				amzGamesClient = null;
				AmazonGamesClient.initialize(LightActivity.instance, me, EnumSet.of(AmazonGamesFeature.Achievements));
				Log.d("LIGHTNING","Amazon Games Client call initialize 2");
			};
		});      
    }



    /*
     *  Connection handlers
     */
    public void onServiceReady(AmazonGamesClient amazonGamesClient) {
		Log.d("LIGHTNING","Amazon Games Client initialized");
		amzGamesClient = amazonGamesClient;
		
		// пробуем сразу достать Player, так как GameCircle достает его асинхронно.
		
        ProfilesClient profilesClient = amzGamesClient.getProfilesClient();
        AGResponseHandle<RequestPlayerProfileResponse> handler = profilesClient.getLocalPlayerProfile();
		
		handler.setCallback(
		  
		  new AGResponseCallback<RequestPlayerProfileResponse>() {
			  @Override
		      public void onComplete(RequestPlayerProfileResponse response) {
		          
		          if (response.isError()) { 
		              Log.d("LIGHTNING","Amazon Profiles Client get player failed");
		          } else {
		              
		              final com.amazon.ags.api.profiles.Player p = response.getPlayer();
                      if (p != null) {
                        
                          player = new Player() {
                              @Override
                              public String getPlayerId() {
                                return p.getPlayerId();
                              }
                              
                              @Override 
                              public String getDisplayName() {
                                return p.getAlias();
                              }
                          };
                      }		              
		          }
		          
		          
		          if (listener != null) {
        		    listener.onConnected();
		          }

		      }
		  }
		  
		);
	};


    public void onServiceNotReady(AmazonGamesStatus result) {

        if (result == AmazonGamesStatus.CANNOT_INITIALIZE) {
            Log.d("LIGHTNING","Amazon GC: Service not ready: CANNOT_INITIALIZE");
        } else if (result == AmazonGamesStatus.INITIALIZING) {
            Log.d("LIGHTNING","Amazon GC: Service not ready: INITIALIZING");
        } else if (result == AmazonGamesStatus.NOT_AUTHENTICATED) {
            Log.d("LIGHTNING","Amazon GC: Service not ready: NOT_AUTHENTICATED (Device not authentificated)");
        } else if (result == AmazonGamesStatus.NOT_AUTHORIZED) {
            Log.d("LIGHTNING","Amazon GC: Service not ready: NOT_AUTHORIZED (The game not authorized)");
        } else if (result == AmazonGamesStatus.SERVICE_CONNECTED){
            Log.d("LIGHTNING","Amazon GC: Service not ready: SERVICE_CONNECTED  (It's OK)");
        }
      

        if (listener != null) {
            listener.onConnectFailed();
        }

	}



    @Override
	public String getPlayerID() {
		if (amzGamesClient == null || !amzGamesClient.isInitialized() || player == null) {
		  return null;
		} else {
		  return player.getPlayerId();
		}   
	}


    @Override
    public Player currentPlayer() {
		if (amzGamesClient == null || !amzGamesClient.isInitialized()) {
		  return null;
		} else {
		  return player;
		}   
	}


    @Override
	public void submitScore(final String leaderboard_id, final long score) {
	}

    @Override
	public void showLeaderboard(final String boardId) {
	}


    @Override
	public void unlockAchievement(final String achievement_id) {
		Lightning.activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
                AchievementsClient acClient = amzGamesClient.getAchievementsClient();
                acClient.updateProgress(achievement_id, 100.0f);				
			}
		});
	}


    @Override
	public void showAchievements() {
		if (amzGamesClient == null) return;
		if (!amzGamesClient.isInitialized()) return;

		Lightning.activity.runOnUiThread(new Runnable() {
			@Override 
			public void run() {
			  AchievementsClient acClient = amzGamesClient.getAchievementsClient();
			  acClient.showAchievementsOverlay();
			}
		});
	}


    @Override
	public void signOut() {
		if (amzGamesClient != null) 
			Lightning.activity.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					amzGamesClient.release();
				}
			});
	}

};
