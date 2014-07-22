package ru.redspell.lightning.gamecenter;


import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.v2.IUiLifecycleHelper;


public class Manager {
	// 0 - Google
	// 1 - Amazon
    private static class Listener implements ConnectionListener {
        public native void onConnected();
        public native void onConnectFailed();
        public native void onDisconnected();
    }

    public static GameCenter createGameCenter(int type) {
        GameCenter gc = type == 0 ? new Google() : new Amazon();
        gc.setConnectionListener(new Listener());

        return gc;
    }
}
