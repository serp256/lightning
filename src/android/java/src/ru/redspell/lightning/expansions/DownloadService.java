package ru.redspell.lightning.expansions;

import com.google.android.vending.expansion.downloader.impl.DownloaderService;

public class DownloadService extends DownloaderService {
    private static String pubKey;
    private static final byte[] SALT = new byte[] { 1, 43, -12, -1, 54, 98, -100, -12, 43, 2, -8, -4, 9, 5, -106, -108, -33, 45, -1, 84 };

    @Override
    public String getPublicKey() {
        return pubKey;
    }

    @Override
    public byte[] getSALT() {
        return SALT;
    }

    @Override
    public String getAlarmReceiverClassName() {
        return AlarmReceiver.class.getName();
    }

    public static void setPubKey(String key) {
        pubKey = key;
    }
}