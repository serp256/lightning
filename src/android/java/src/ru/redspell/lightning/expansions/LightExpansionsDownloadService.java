package ru.redspell.lightning.expansions;

import com.google.android.vending.expansion.downloader.impl.DownloaderService;

public class LightExpansionsDownloadService extends DownloaderService {
    // private static final String BASE64_PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk4VHm23geqp5lhRVJDciZbEjPX+eKSPhD7LnW9p5xfu7JxfWYsLVPkp8EeGLjCTM/PaybmZeR/bxaDX2euTeqKLRDAfNN+/LiKLsO9mHm6ioZXo6DnoBJ8uFCd/UMYZjGwMMd6iik7UkCqfmPCQRRxk0Sdr2K6+TXVGjk8AiktuNfmcARo10MgEdVpErfHEMDZJxI0CJQDHvDigfVabGyVRvz3zlvSphSdIFr5Movm1+av2cZFlPfEc2Mtibnw9wUgPkIfhLuzP67eCnlxR7+jBfFNznEkJvI4iaM10G4bEo26HMemI7wGYhwnA2L0VlEjU4OrZPZEWYI3erxtt4wwIDAQAB";
    private static String pubKey;
    private static final byte[] SALT = new byte[] { 1, 43, -12, -1, 54, 98, -100, -12, 43, 2, -8, -4, 9, 5, -106, -108, -33, 45, -1, 84 };

    @Override
    public String getPublicKey() {
        // return BASE64_PUBLIC_KEY;
        return pubKey;
    }

    @Override
    public byte[] getSALT() {
        return SALT;
    }

    @Override
    public String getAlarmReceiverClassName() {
        return LightExpansionsAlarmReceiver.class.getName();
    }

    public static void setPubKey(String key) {
        pubKey = key;
    }
}