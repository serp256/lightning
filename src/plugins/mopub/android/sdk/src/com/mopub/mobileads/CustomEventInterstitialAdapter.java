package com.mopub.mobileads;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

import com.mopub.mobileads.CustomEventInterstitial;
import com.mopub.mobileads.CustomEventInterstitial.CustomEventInterstitialListener;

import android.content.Context;
import android.util.Log;

public class CustomEventInterstitialAdapter extends BaseInterstitialAdapter implements CustomEventInterstitialListener {
    private CustomEventInterstitial mCustomEventInterstitial;
    private Context mContext;
    private Map<String, Object> mLocalExtras = new HashMap<String, Object>();
    private Map<String, String> mServerExtras = new HashMap<String, String>();
    
    @Override
    public void init(MoPubInterstitial moPubInterstitial, String className) {
        init(moPubInterstitial, className, null);
    }
    
    public void init(MoPubInterstitial moPubInterstitial, String className, String jsonParams) {
        super.init(moPubInterstitial, jsonParams);
        
        mContext = moPubInterstitial.getActivity();
        
        Log.d("MoPub", "Attempting to invoke custom event: " + className);
        
        try {
            // Instantiate the provided custom event class, if possible
            Class<? extends CustomEventInterstitial> interstitialClass = Class.forName(className)
                    .asSubclass(CustomEventInterstitial.class);
            Constructor<?> interstitialConstructor = interstitialClass.getConstructor((Class[]) null);
            mCustomEventInterstitial = (CustomEventInterstitial) interstitialConstructor.newInstance();
        } catch (Exception exception) {
            Log.d("MoPub", "Couldn't locate or instantiate custom event: " + className + ".");
            if (mAdapterListener != null) mAdapterListener.onNativeInterstitialFailed(this,
                    MoPubErrorCode.ADAPTER_NOT_FOUND);
        }
        
        // Attempt to load the JSON extras into mServerExtras.
        try {
            mServerExtras = Utils.jsonStringToMap(jsonParams);
        } catch (Exception exception) {
            Log.d("MoPub", "Failed to create Map from JSON: " + jsonParams);
        }
        
        mLocalExtras = mInterstitial.getLocalExtras();
    }
    
    @Override
    public void loadInterstitial() {
        if (isInvalidated() || mCustomEventInterstitial == null) return;
        
        mCustomEventInterstitial.loadInterstitial(mContext, this, mLocalExtras, mServerExtras);
    }
    
    @Override
    public void showInterstitial() {
        if (isInvalidated() || mCustomEventInterstitial == null) return;
        
        mCustomEventInterstitial.showInterstitial();
    }

    @Override
    public void invalidate() {
        if (mCustomEventInterstitial != null) mCustomEventInterstitial.onInvalidate();
        mCustomEventInterstitial = null;
        mContext = null;
        mServerExtras = null;
        mLocalExtras = null;
        super.invalidate();
    }

    /*
     * CustomEventInterstitial.Listener implementation
     */
    @Override
    public void onInterstitialLoaded() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialLoaded(this);
    }

    @Override
    public void onInterstitialFailed(MoPubErrorCode errorCode) {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) {
            if (errorCode == null) {
                errorCode = MoPubErrorCode.UNSPECIFIED;
            }
            mAdapterListener.onNativeInterstitialFailed(this, errorCode);
        }
    }
    
    @Override
    public void onInterstitialShown() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialShown(this);
    }

    @Override
    public void onInterstitialClicked() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialClicked(this);
    }

    @Override
    public void onLeaveApplication() {
        onInterstitialClicked();
    }

    @Override
    public void onInterstitialDismissed() {
        if (isInvalidated()) return;
        
        if (mAdapterListener != null) mAdapterListener.onNativeInterstitialDismissed(this);
    }
}
