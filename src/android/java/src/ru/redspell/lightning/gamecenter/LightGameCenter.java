package ru.redspell.lightning.gamecenter;

public interface LightGameCenter {

    public void setConnectionListener(LightGameCenterConnectionListener listener);

    public void connect();
  
    public String getPlayerID();
  
    public LightGameCenterPlayer currentPlayer();
  
    public void showAchievements();
		public void showLeaderboard (final String boardId);
    
    public void unlockAchievement(final String achievement_id);
		public void submitScore(final String leaderboard_id, final long score); 
  
    public void signOut();  
}






