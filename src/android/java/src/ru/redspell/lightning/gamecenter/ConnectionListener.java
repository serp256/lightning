package ru.redspell.lightning.gamecenter;

public interface ConnectionListener {
    
    public void onConnected();
    
    public void onConnectFailed();
    
    public void onDisconnected();
}
