package com.mopub.mobileads;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;

import com.mopub.mobileads.CustomEventBanner;
import com.mopub.mobileads.CustomEventBanner.CustomEventBannerListener;

import android.content.Context;
import android.util.Log;
import android.view.View;

public class CustomEventBannerAdapter extends BaseAdapter implements CustomEventBannerListener {
    private Context mContext;
    private CustomEventBanner mCustomEventBanner;
    private Map<String, Object> mLocalExtras = new HashMap<String, Object>();
    private Map<String, String> mServerExtras = new HashMap<String, String>();
    
    @Override
    public void init(MoPubView moPubView, String className) {
        init(moPubView, className, null);
    }
    
    public void init(MoPubView moPubView, String className, String jsonParams) {
        super.init(moPubView, jsonParams);
        
        mContext = moPubView.getContext();
        
        Log.d("MoPub", "Attempting to invoke custom event: " + className);
        
        try {
            // Instantiate the provided custom event class, if possible
            Class<? extends CustomEventBanner> bannerClass = Class.forName(className)
                    .asSubclass(CustomEventBanner.class);
            Constructor<?> bannerConstructor = bannerClass.getConstructor((Class[]) null);
            mCustomEventBanner = (CustomEventBanner) bannerConstructor.newInstance();
        } catch (Exception exception) {
            Log.d("MoPub", "Couldn't locate or instantiate custom event: " + className + ".");
            mMoPubView.loadFailUrl(MoPubErrorCode.ADAPTER_NOT_FOUND);
            return;
        }
        
        // Attempt to load the JSON extras into mServerExtras.
        try {
            mServerExtras = Utils.jsonStringToMap(jsonParams);
        } catch (Exception exception) {
            Log.d("MoPub", "Failed to create Map from JSON: " + jsonParams + exception.toString());
        }
        
        mLocalExtras = mMoPubView.getLocalExtras();
    }
    
    @Override
    public void loadAd() {
        if (isInvalidated() || mCustomEventBanner == null) return;
        
        mCustomEventBanner.loadBanner(mContext, this, mLocalExtras, mServerExtras);
    }

    @Override
    public void invalidate() {
        if (mCustomEventBanner != null) mCustomEventBanner.onInvalidate();
        mContext = null;
        mCustomEventBanner = null;
        mLocalExtras = null;
        mServerExtras = null;
        super.invalidate();
    }
    
    /*
     * CustomEventBanner.Listener implementation
     */
    @Override
    public void onBannerLoaded(View bannerView) {
        if (isInvalidated()) return;
        
        if (mMoPubView != null) {
            mMoPubView.nativeAdLoaded();
            mMoPubView.setAdContentView(bannerView);
            mMoPubView.trackNativeImpression();
        }
    }

    @Override
    public void onBannerFailed(MoPubErrorCode errorCode) {
        if (isInvalidated()) return;
        
        if (mMoPubView != null) {
            if (errorCode == null) {
                errorCode = MoPubErrorCode.UNSPECIFIED;
            }
            mMoPubView.loadFailUrl(errorCode);
        }
    }

    @Override
    public void onBannerClicked() {
        if (isInvalidated()) return;
        
        if (mMoPubView != null) mMoPubView.registerClick();
    }
    
    @Override
    public void onLeaveApplication() {
        onBannerClicked();
    }
}
