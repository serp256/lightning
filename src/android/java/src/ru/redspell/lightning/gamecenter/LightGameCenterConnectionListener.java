package ru.redspell.lightning.gamecenter;

public interface LightGameCenterConnectionListener {
    
    public void onConnected();
    
    public void onConnectFailed();
    
    public void onDisconnected();
}
