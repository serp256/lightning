package ru.redspell.lightning.gamecenter;

public interface GameCenter {

    public void setConnectionListener(ConnectionListener listener);

    public void connect();
  
    public String getPlayerID();
  
    public Player currentPlayer();
  
    public void showAchievements();
		public void showLeaderboard (final String boardId);
    
    public void unlockAchievement(final String achievement_id);
		public void submitScore(final String leaderboard_id, final long score); 
  
    public void signOut();  
}






