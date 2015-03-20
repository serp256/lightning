package ru.redspell.lightning.payments;

public class Payments {
    public interface IPayments {
        void init(String[] skus, String marketType);
        void purchase(String sku);
        void consume(Object purchase);
        void inventory();
        String getOriginalJson(Object purchase);
        String getToken(Object purchase);
        String getSignature(Object purchase);
    }

    private static IPayments instance;

    private static IPayments getInstance() throws Exception {
        if (instance == null) {
            throw new Exception("payments not initialized yet");
        }

        return instance;
    }

    public static void purchase(String sku) throws Exception {
        getInstance().purchase(sku);
    }

    public static void consume(Object purchase) throws Exception {
        getInstance().consume(purchase);
    }

    public static void inventory() throws Exception {
        getInstance().inventory();
    }

    public static void init(String[] skus, String marketType) throws Exception {
        if (instance != null) {
            throw new Exception("payments already initialized");
        }

        do {
            if (marketType.contentEquals("com.samsung.apps")) {
                instance = new Samsung(false);
                break;
            }

            if (marketType.contentEquals("com.samsung.apps.dev")) {
                instance = new Samsung(true);
                break;
            }

            instance = new Openiab();
        } while(false);

        getInstance().init(skus, marketType);
    }

    public static String getOriginalJson(Object purchase) throws Exception {
        try {
            return getInstance().getOriginalJson(purchase);
        } catch (Exception e) {
            ru.redspell.lightning.utils.Log.d("LIGHTNING", "exception " + e.toString());
            return "";
        }
    }

    public static String getToken(Object purchase) throws Exception {
        return getInstance().getToken(purchase);
    }

    public static String getSignature(Object purchase) throws Exception {
        return getInstance().getSignature(purchase);
    }

    public static native void purchaseSuccess(String sku, Object purchase, boolean restored);
    public static native void purchaseFail(String sku, String reason);
    public static native void purchaseRegister(String sku, String price);
}
