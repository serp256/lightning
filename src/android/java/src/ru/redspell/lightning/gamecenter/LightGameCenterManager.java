package ru.redspell.lightning.gamecenter;


import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.IUiLifecycleHelper;


public class LightGameCenterManager {
	// 0 - Google
	// 1 - Amazon
    private static class Listener implements LightGameCenterConnectionListener {
        public native void onConnected();
        public native void onConnectFailed();
        public native void onDisconnected();
    }

    public static LightGameCenter createGameCenter(int type) {
        LightGameCenter gc = type == 0 ? new LightGameCenterAndroid() : new LightGameCenterAmazon();
        gc.setConnectionListener(new Listener());

        return gc;
    }
}
