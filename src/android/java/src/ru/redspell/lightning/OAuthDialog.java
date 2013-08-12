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
import java.net.MalformedURLException;

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
    private ProgressDialog mSpinner;
    private ImageView mCrossImage;
    private WebView mWebView;
    private FrameLayout mContent;

    private String mRedirectUrlPath;
    private Boolean mAuthorizing = false;

    public interface UrlRunnable {
        public void run(String url);
    }

    private static class DefaultDialogClosedRunnable implements UrlRunnable {
        @Override
        public native void run(String url);
    }

    private static class DefaultRedirectHandler implements UrlRunnable {
        @Override
        public native void run(String url);
    }

    public OAuthDialog(Context context, String url) {
        this(context, url, new DefaultDialogClosedRunnable(), new DefaultRedirectHandler(), null);
    }

    private UrlRunnable closeHandler;
    private UrlRunnable redirectHandler;

    public OAuthDialog(Context context, String url, UrlRunnable closeHandler, UrlRunnable redirectHandler, String redirectUrlPath) {
        super(context, android.R.style.Theme_Translucent_NoTitleBar);

        this.closeHandler = closeHandler;
        this.redirectHandler = redirectHandler;

        mUrl = url;

        if (redirectUrlPath != null) {
            mRedirectUrlPath = redirectUrlPath;
        } else {
            try {
                Matcher m = Pattern.compile(".*redirect_uri=([^&]+).*").matcher((new URL(url)).getQuery());

                if (m.matches ()) {
                    mRedirectUrlPath = (new URL(java.net.URLDecoder.decode(m.group(1), "ASCII"))).getPath();
                }
            }
            catch (MalformedURLException e) {}
            catch (java.io.UnsupportedEncodingException e) {}            
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
        mCrossImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // mListener.onCancel();
                OAuthDialog.this.close();
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

    @Override
    public void dismiss() {
        Log.d("LIGHTNING", "dismiss call");

        mWebView.stopLoading();        
        super.dismiss();
        mWebView.destroy();
    }

    public void close() {
        dismiss();
        if (closeHandler != null) {
            LightView.instance.queueEvent(new Runnable() { @Override public void run() { closeHandler.run(mRedirectUrlPath + "#error=access_denied"); }});
        }
    }

    private class WebViewClient extends android.webkit.WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            Log.d("LIGHTNING", "shouldOverrideUrlLoading " + url);

            if (redirectHandler != null) {
                try {
                    Log.d("LIGHTNING", "mRedirectUrlPath " + mRedirectUrlPath);
                    Log.d("LIGHTNING", "(new URL(url)).getPath() " + (new URL(url)).getPath());
                    if (mRedirectUrlPath != null && mRedirectUrlPath.contentEquals((new URL(url)).getPath())) {
                        final String _url = new String(url);

                        LightView.instance.queueEvent(new Runnable() {
                            public void run() {
                                redirectHandler.run(_url);
                            }
                        });

                        mSpinner.dismiss();
                        OAuthDialog.this.dismiss();
                        return true;
                    }
                } catch (MalformedURLException e) {}
            }

            return false;
        }

        @Override
        public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
            Log.d("LIGHTNING", "onReceivedError");

            super.onReceivedError(view, errorCode, description, failingUrl);
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
            mContent.setBackgroundColor(Color.TRANSPARENT);
            mWebView.setVisibility(View.VISIBLE);
            mCrossImage.setVisibility(View.VISIBLE);



    // if ([@"security breach" isEqualToString: content] || [@"<pre style=\"word-wrap: break-word; white-space: pre-wrap;\">{\"error\":\"invalid_request\",\"error_description\":\"Security Error\"}</pre>" isEqualToString: content] ) {
    //     NSString * errorUrl = [NSString stringWithFormat: @"%@#error=access_denied", _redirectURIpath];
    //     [[LightViewController sharedInstance] dismissModalViewControllerAnimated: NO];
    //     caml_acquire_runtime_system();
    //     value *mlf = (value*)caml_named_value("oauth_redirected");
    //     if (mlf != NULL) {                                                                                                        
    //         caml_callback(*mlf, caml_copy_string([errorUrl UTF8String]));
    //     }
    //     caml_release_runtime_system();
    //     return;
    // } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    //     NSLog(@"345");

    //     [self setViewportWidth: 540.0f];
    // }

        }
    }
}