package ru.redspell.lightning.gamecenter;


import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.IUiLifecycleHelper;


public class LightGameCenterManager {
	// 0 - Google
	// 1 - Amazon
    static public LightGameCenter createGameCenter(int type) {

        LightGameCenterConnectionListener connListener = new LightGameCenterConnectionListener() {
    
              public void onConnected() {                
                  LightActivity.instance.lightView.queueEvent(new ConnectionSuccessCallbackRunnable());  
              }
    
              public void onConnectFailed() {
                  LightActivity.instance.lightView.queueEvent(new ConnectionFailedCallbackRunnable());
              }
    
              public void onDisconnected() {
                  LightActivity.instance.lightView.queueEvent(new ConnectionDisconnectCallbackRunnable());
              }
          };


        LightGameCenter gc = null;
		if (type == 0)
			gc = new LightGameCenterAndroid();
		else
			gc = new LightGameCenterAmazon();
        gc.setConnectionListener(connListener);
        return gc;        
    }


    

	static private class ConnectionSuccessCallbackRunnable implements Runnable {
		native public void run();
	}

	static private class ConnectionFailedCallbackRunnable implements Runnable {
		native public void run();
	}

	static private class ConnectionDisconnectCallbackRunnable implements Runnable {
		native public void run();
	}

}
