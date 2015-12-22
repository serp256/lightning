package ru.redspell.lightning.plugins;

import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import java.net.URL;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.net.MalformedURLException;

public class LightXsollaDialog extends Dialog {

    // static final int FB_BLUE = 0xFF6D84B4;
    static final float[] DIMENSIONS_DIFF_LANDSCAPE = {20, 60};
    static final float[] DIMENSIONS_DIFF_PORTRAIT = {40, 60};
    static final FrameLayout.LayoutParams FILL = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.FILL_PARENT, ViewGroup.LayoutParams.FILL_PARENT);
    static final int MARGIN = 4;
    static final int PADDING = 2;
    // static final String DISPLAY_STRING = "touch";
    // static final String FB_ICON = "icon.png";

    private String mUrl;
    private ProgressDialog mSpinner;
    private ImageView mCrossImage;
    private WebView mWebView;
    private FrameLayout mContent;

    private String mRedirectUrl;

		private static abstract class Callback implements Runnable {
			protected int success;
			protected int fail;

			public abstract void run();

			public Callback(int success, int fail) {
				this.success = success;
				this.fail = fail;
			}
		}

		private static class Success extends Callback {
			public Success(int success, int fail) {
				super(success, fail);
			}

			public native void nativeRun(int success, int fail);

			public void run() {
				nativeRun(success, fail);
			}
		}

		private static class Fail extends Callback {
			private String reason;

			public Fail(int success, int fail, String reason) {
				super(success, fail);
				this.reason = reason;
			}

			public native void nativeRun(int fail, String reason, int success);

			public void run() {
				nativeRun(fail, reason, success);
			}
		}

		private static int success;
		private static int fail;

    public LightXsollaDialog(Context context, String token, String redirectUrl, final int s, final int f, boolean isSandbox) {
        super(context, android.R.style.Theme_Translucent_NoTitleBar);

				success = s;
				fail = f;
				Log.d ("LIGHTNING","isSandbox " + isSandbox);
				if (isSandbox) {
					mUrl = "https://sandbox-secure.xsolla.com/paystation2/?access_token="+token;
				}
				else {
					mUrl = "https://secure.xsolla.com/paystation2/?access_token="+token;
				}

				Log.d ("LIGHTNING","mUrl " + mUrl);
        if (redirectUrl != null) {
            mRedirectUrl = redirectUrl;
				}
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d("LIGHTNING", "onCreate");
        super.onCreate(savedInstanceState);
        mSpinner = new ProgressDialog(getContext());
        mSpinner.requestWindowFeature(Window.FEATURE_NO_TITLE);
        mSpinner.setMessage("Loading...");
        
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        mContent = new FrameLayout(getContext());

        /* Create the 'x' image, but don't add to the mContent layout yet
         * at this point, we only need to know its drawable width and height 
         * to place the webview
         */
        createCrossImage();
        
        /* Now we know 'x' drawable width and height, 
         * layout the webivew and add it the mContent layout
         */
        int crossWidth = mCrossImage.getDrawable().getIntrinsicWidth();
        setUpWebView(crossWidth / 2);
        
        /* Finally add the 'x' image to the mContent layout and
         * add mContent to the Dialog view
         */
        mContent.addView(mCrossImage, new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
        addContentView(mContent, new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
    }
    
    private void createCrossImage() {
        Log.d("LIGHTNING", "createCrossImage");
        mCrossImage = new ImageView(getContext());
        mCrossImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // mListener.onCancel();
                LightXsollaDialog.this.close();
            }
        });
        Drawable crossDrawable = getContext().getResources().getDrawable(ru.redspell.lightning.R.drawable.close);
        mCrossImage.setImageDrawable(crossDrawable);
        /* 'x' should not be visible while webview is loading
         * make it visible only after webview has fully loaded
        */
        mCrossImage.setVisibility(View.INVISIBLE);
    }

    private void setUpWebView(int margin) {
        Log.d("LIGHTNING", "setUpWebView");
        LinearLayout webViewContainer = new LinearLayout(getContext());
        mWebView = new WebView(getContext());
        mWebView.setVerticalScrollBarEnabled(false);
        mWebView.setHorizontalScrollBarEnabled(false);
        mWebView.setWebViewClient(new LightXsollaDialog.WebViewClient());
        mWebView.getSettings().setJavaScriptEnabled(true);
        mWebView.loadUrl(mUrl);
        mWebView.setLayoutParams(FILL);
        mWebView.setVisibility(View.INVISIBLE);
        mWebView.getSettings().setSavePassword(false);
        
        webViewContainer.setPadding(margin, margin, margin, margin);
        webViewContainer.addView(mWebView);
        mContent.addView(webViewContainer);
    }

    @Override
    public void onDetachedFromWindow() {
        // mWebView.removeAllViews();
        mWebView.destroy();
    }

    @Override
    public void dismiss() {
        Log.d("LIGHTNING", "dismiss call");

        mWebView.stopLoading();        
        super.dismiss();
    }

    public void close() {
        Log.d("LIGHTNING", "close");
        dismiss();
				(new Fail(success, fail, "Xsolla: unsuccessful payment")).run();
    }

    private class WebViewClient extends android.webkit.WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.d("LIGHTNING", "shouldOverrideUrlLoading " + url);

						Log.d("LIGHTNING", "mRedirectUrlPath " + mRedirectUrl);
						if (mRedirectUrl != null && mRedirectUrl.contentEquals(url)) {
								//final String _url = new String(url);

								//onRedirect(_url);
								mSpinner.dismiss();
								LightXsollaDialog.this.dismiss();
								(new Success(success, fail)).run();
								return true;
						}

            return false;
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            Log.d("LIGHTNING", "onReceivedError");

            super.onReceivedError(view, errorCode, description, failingUrl);
            LightXsollaDialog.this.dismiss();
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            Log.d("LIGHTNING", "onPageStarted");

            super.onPageStarted(view, url, favicon);
            mSpinner.show();
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            Log.d("LIGHTNING", "onPageFinished");            
            super.onPageFinished(view, url);
            mSpinner.dismiss();
            mContent.setBackgroundColor(Color.TRANSPARENT);
            mWebView.setVisibility(View.VISIBLE);
            mCrossImage.setVisibility(View.VISIBLE);
        }
    }
}
