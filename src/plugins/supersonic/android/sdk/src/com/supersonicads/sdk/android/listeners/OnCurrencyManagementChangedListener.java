package com.supersonicads.sdk.android.listeners;

/**
 * Interface definition for a callback to be invoked when virtual currency
 * management is changed.
 */
public interface OnCurrencyManagementChangedListener {

    /**
     * Called when the virtual credit balance is available.
     */
    public void onGotBalanceForUser(int currentAmount);

    /**
     * Called when then virtual credit balance change has committed.
     */
    public void onCurrencyChangeRequest(String transactionId);

}
