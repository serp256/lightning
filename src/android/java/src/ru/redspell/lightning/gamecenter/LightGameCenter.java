package ru.redspell.lightning.gamecenter;

public interface LightGameCenter {

    public void setConnectionListener(LightGameCenterConnectionListener listener);

    public void connect();
  
    public String getPlayerID();
  
    public LightGameCenterPlayer currentPlayer();
  
    public void showAchievements();
    
    public void unlockAchievement(final String achievement_id);
  
    public void signOut();  
}






