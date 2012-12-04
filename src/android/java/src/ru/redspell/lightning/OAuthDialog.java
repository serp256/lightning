package ru.redspell.lightning;

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

public class OAuthDialog extends Dialog {

    // static final int FB_BLUE = 0xFF6D84B4;
    static final float[] DIMENSIONS_DIFF_LANDSCAPE = {20, 60};
    static final float[] DIMENSIONS_DIFF_PORTRAIT = {40, 60};
    static final FrameLayout.LayoutParams FILL = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.FILL_PARENT, ViewGroup.LayoutParams.FILL_PARENT);
    static final int MARGIN = 4;
    static final int PADDING = 2;
    // static final String DISPLAY_STRING = "touch";
    // static final String FB_ICON = "icon.png";

    private String mUrl;
    private DialogListener mListener;
    private ProgressDialog mSpinner;
    private ImageView mCrossImage;
    private WebView mWebView;
    private FrameLayout mContent;

    public OAuthDialog(Context context, String url, DialogListener listener) {
        // super(context);
        super(context, android.R.style.Theme_Translucent_NoTitleBar);
        mUrl = url;
        mListener = listener;

        Matcher m = Pattern.compile(".*redirect_uri=([^&]+).*").matcher((new URL(url)).getQuery());

        if (m.matches ()) {
            Log.d("LIGHTNING", m.group(1));
        } else {
            Log.d("LIGHTNING", "xyu tam");
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
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
        mCrossImage = new ImageView(getContext());
        // Dismiss the dialog when user click on the 'x'
        mCrossImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mListener.onCancel();
                OAuthDialog.this.dismiss();
            }
        });
        Drawable crossDrawable = getContext().getResources().getDrawable(R.drawable.close);
        mCrossImage.setImageDrawable(crossDrawable);
        /* 'x' should not be visible while webview is loading
         * make it visible only after webview has fully loaded
        */
        mCrossImage.setVisibility(View.INVISIBLE);
    }

    private void setUpWebView(int margin) {
        LinearLayout webViewContainer = new LinearLayout(getContext());
        mWebView = new WebView(getContext());
        mWebView.setVerticalScrollBarEnabled(false);
        mWebView.setHorizontalScrollBarEnabled(false);
        mWebView.setWebViewClient(new OAuthDialog.WebViewClient());
        mWebView.getSettings().setJavaScriptEnabled(true);
        mWebView.loadUrl(mUrl);
        mWebView.setLayoutParams(FILL);
        mWebView.setVisibility(View.INVISIBLE);
        mWebView.getSettings().setSavePassword(false);
        
        webViewContainer.setPadding(margin, margin, margin, margin);
        webViewContainer.addView(mWebView);
        mContent.addView(webViewContainer);
    }

    private class WebViewClient extends android.webkit.WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.d("LIGHTNING", "shouldOverrideUrlLoading " + url);
            // getContext().startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
            //OAuthDialog.this.dismiss();
            return false;
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            Log.d("LIGHTNING", "onReceivedError");

            super.onReceivedError(view, errorCode, description, failingUrl);
            // mListener.onError(new DialogError(description, errorCode, failingUrl));
            mListener.onError();
            OAuthDialog.this.dismiss();
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
            /* 
             * Once webview is fully loaded, set the mContent background to be transparent
             * and make visible the 'x' image. 
             */
            mContent.setBackgroundColor(Color.TRANSPARENT);
            mWebView.setVisibility(View.VISIBLE);
            mCrossImage.setVisibility(View.VISIBLE);
        }
    }

    public interface DialogListener {
        public void onComplete(Bundle values);
        public void onError();
        public void onCancel();
    }
}