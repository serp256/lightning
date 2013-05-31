package com.supersonicads.sdk.android;

import java.io.Serializable;

/**
 * Object stores parameters retrieves when Brand's connection successes.
 */
public class BrandConnectParameters implements Serializable {

    private static final long serialVersionUID = -7004567318499169472L;

    private final int availableAds;
    private final int totalCredits;
    private final int firstAdCredit;

    public BrandConnectParameters(int availableAds, int totalCredits, int firstAdCredit) {
        this.availableAds = availableAds;
        this.totalCredits = totalCredits;
        this.firstAdCredit = firstAdCredit;
    }

    /**
     * Returns the number of available ads.
     */
    public int getAvailableAds() {
        return availableAds;
    }

    /**
     * Returns the number of credits available for a user who will watch all the
     * ads.
     */
    public int getTotalCredits() {
        return totalCredits;
    }

    /**
     * Returns the Number of credits available for watching the first ad.
     */
    public int getFirstAdCredit() {
        return firstAdCredit;
    }

}
