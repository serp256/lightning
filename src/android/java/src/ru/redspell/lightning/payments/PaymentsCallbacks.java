package ru.redspell.lightning.payments;

import java.lang.Runnable;
import ru.redspell.lightning.LightView;

public class PaymentsCallbacks {
    private static class Success implements Runnable {
        private String sku;
        private String transactionId;
        private String receipt;
        private String signature;
        private boolean restored;

        public Success(String sku, String transactionId, String receipt, String signature, boolean restored) {
            this.sku = sku;
            this.transactionId = transactionId;
            this.receipt = receipt;
            this.signature = signature;
            this.restored = restored;
        }

        public native void run();
    }

    private static class Fail implements Runnable {
        private String sku;
        private String reason;

        public Fail(String sku, String reason) {
            this.sku = sku;
            this.reason = reason;
        }

        public native void run();
    }

    public static void success(String sku, String transactionId, String receipt, String signature, boolean restored) {
        LightView.instance.queueEvent(new Success(sku, transactionId, receipt, signature, restored));
    }

    public static void fail(String sku, String reason) {
        LightView.instance.queueEvent(new Fail(sku, reason));
    }
}