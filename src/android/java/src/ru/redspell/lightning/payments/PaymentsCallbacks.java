package ru.redspell.lightning.payments;

public class PaymentsCallbacks {
    public static native void success(String sku, String transactionId, String receipt, String signature, boolean restored);
    public static native void fail(String sku, String reason);
}