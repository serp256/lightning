package com.supersonicads.sdk.android;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Map;

import org.itri.html5webview.HTML5WebView;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Color;
import android.net.MailTo;
import android.net.Uri;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.Toast;

/**
 * Activity that presents the Brand Connect webviews and offer wall.
 */
public class WebViewActivity extends Activity implements DialogInterface.OnClickListener {

    private static final LayoutParams MATCH_PARENT_LAYOUT_PARAMS = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
    private static final String ABOUT_BLANK = "about:blank";
    
    private final int MAIL_TO = 1001;
    private final int PLAY_STORE = 1002;

    class MyWebViewClient extends WebViewClient {
    	
        private final Map<String, String> emailHeaders = new HashMap<String, String>();

        public MyWebViewClient() {
        	
            emailHeaders.put("to", Intent.EXTRA_EMAIL);
            emailHeaders.put("body", Intent.EXTRA_TEXT);
            emailHeaders.put("cc", Intent.EXTRA_CC);
            emailHeaders.put("subject", Intent.EXTRA_SUBJECT);
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
        	
            if (MailTo.isMailTo(url)) {
            	
                // MailTo is buggy because it decodes the URL before it splits, this is a rudimentary implementation that reaches the same result, although less elegantly.

                Intent intent = new Intent(Intent.ACTION_SEND);
                intent.setType("message/rfc822");

                String query = url.substring(url.indexOf('?') + 1);
                
                for (String paramBodyString : query.split("&")) {
                	
                    String[] paramBody = paramBodyString.split("=", 2);
                    
                    if (paramBody.length == 2) {
                    	
                        String param = paramBody[0];
                        String body = decodeText(paramBody[1]);
                        
                        if (emailHeaders.containsKey(param)) {
                        	
                            intent.putExtra(emailHeaders.get(param), body);
                        }
                    }
                }

                startActivityForResult(intent, MAIL_TO);
                return true;
                
            } else if (url != null && url.contains("://") && url.toLowerCase().startsWith("market:")) {
            	
            	Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            	startActivityForResult(intent, PLAY_STORE);
                return true;
                
            } else {
            	
                return false;
            }
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    	
    	super.onActivityResult(requestCode, resultCode, data);
    	
    	switch (requestCode) {	
		
			case PLAY_STORE:																				
				onBackPressed();							
				break;				
			default:	
				break;
    	}
    }

    /*
     * The whole Activity's container view, this reference is used to handle the
     * Dynamic placing it's child views after the creation or destruction of the
     * ToolBar.
     */
    private RelativeLayout mContainer;

    private HTML5WebView mWebView;
    private FrameLayout mWebViewFrameContainer;
    private RelativeLayout mToolBar;

    /*
     * Members for controlling the behavior of the confirmation "Close" message.
     */
    private boolean mShouldConfirmCloseMessageAppear = false;
    private String mShouldConfirmCloseMessage;
    private String mShouldConfirmClosePositiveButtonText;
    private String mShouldConfirmCloseNegativeButtonText;

    public static boolean mEnablePortrait = Constants.ENABLE_PORTRAIT;
    public static boolean mIsTextClickable = Constants.VIDEO_TEXT_CLICKALBLE;

    // For JS test methods.
    public static boolean isVideoPlayerClosed = false;

    // ================================================================================
    // ACTIVITY LIFECYCLE
    // ================================================================================

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = getIntent();
        if (intent == null) {
            // Error..
            finish();
            return;
        }

        // Build the window programmatically.
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        initializeUserControls();

        // Gets the url to load in the web view.
        String sourceUrl = intent.getStringExtra(Constants.KEY_ACTIVITY_DATA_URL);
        if (sourceUrl == null) {
            // Error..
            finish();

            return;
        }

        Logger.i("WebViewActivity", "loading url: " + sourceUrl);

        // Load file
        mWebView.loadUrl(sourceUrl);
    }

    @Override
    protected void onPause() {
        super.onPause();

        if (mWebView.inCustomView()) {
            mWebView.hideCustomView();
        }
    }

    // ================================================================================
    // PRIVATE HELPER METHODS.
    // ================================================================================

    /**
     * Initializes and builds the User controls of this activity.
     */
    @SuppressLint("SetJavaScriptEnabled")
    private void initializeUserControls() {

        // Create the container of the whole activity.
        mContainer = new RelativeLayout(this);

        // Create the WebView and adds it to the container.
        mWebView = new HTML5WebView(this);
        mWebViewFrameContainer = mWebView.getLayout();
        mContainer.addView(mWebViewFrameContainer, MATCH_PARENT_LAYOUT_PARAMS);

        // Create the JavaScript and email interfaces and attach them to the
        // WebView.
        mWebView.addJavascriptInterface(new JsInterface(), "Android");
        mWebView.setWebViewClient(new MyWebViewClient());

        // Disable caching and fix a bug that happens on some devices and
        // presents a white strip.
        mWebView.getSettings().setAppCacheEnabled(false);
        mWebView.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);

        // Set the activity's content.
        setContentView(mContainer, MATCH_PARENT_LAYOUT_PARAMS);
    }

    /**
     * Decodes text given from the URL format to plain text.
     * 
     * @param text
     *            to encode.
     * @return encoded text.
     */
    private static String decodeText(String text) {
        try {
            return URLDecoder.decode(text, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            // Should never happen, UTF-8 is guaranteed to be present
            throw new RuntimeException(e);
        }
    }

    @Override
    public void onBackPressed() {
        if (mWebView.inCustomView()) {
            mWebView.hideCustomView();
        } else if (mWebView.canGoBack()) {
            // WebView has history, go back inside it
            mWebView.goBack();
        } else {
            // The WebView doesn't contain any history, Checks if it should
            // popup the confirm close dialog
            if (mShouldConfirmCloseMessageAppear) {
                showCloseConfirmDialog();
            } else {
                // Clears the WebView, exits from the activity
                mWebView.loadUrl(ABOUT_BLANK);
                super.onBackPressed();
            }
        }
    }

    @Override
    public void onClick(DialogInterface dialog, int which) {
        if (which == DialogInterface.BUTTON_POSITIVE) {
            // Clears the WebView, exits from the activity
            mWebView.loadUrl(ABOUT_BLANK);
            finish();
        }
    }

    private void showCloseConfirmDialog() {
        new AlertDialog.Builder(this).setMessage(decodeText(mShouldConfirmCloseMessage))
                .setPositiveButton(decodeText(mShouldConfirmClosePositiveButtonText), this)
                .setNegativeButton(decodeText(mShouldConfirmCloseNegativeButtonText), this).show();
    }

    // ================================================================================
    // JAVASCRIPT INTERFACE.
    // ================================================================================

    /**
     * Interface for handling JavaScript functions in the WebView.
     */
    public class JsInterface {
        /**
         * Displays a dialog to the user with text and custom "OK" button.
         */
        @JavascriptInterface
        public void displayMessage(String message, String buttonText) {
            new AlertDialog.Builder(WebViewActivity.this).setMessage(decodeText(message))
                    .setPositiveButton(decodeText(buttonText), null).show();
        }

        /**
         * Creates a dialog to display the user before he exits the activity
         * with custom text and "OK" and "CANCEL" buttons.
         */
        @JavascriptInterface
        public void shouldConfirmClose(boolean shouldConfirmCloseMessageAppear, String message,
                String positiveButtonText, String negativeButtonText) {
            mShouldConfirmCloseMessageAppear = shouldConfirmCloseMessageAppear;
            mShouldConfirmCloseMessage = message;
            mShouldConfirmClosePositiveButtonText = positiveButtonText;
            mShouldConfirmCloseNegativeButtonText = negativeButtonText;
        }

        /**
         * Sets flag if the "Close" dialog should appear or not if the user
         * presses the "Back" button.
         */
        @JavascriptInterface
        public void shouldConfirmClose(boolean shouldConfirmCloseMessageAppear) {
            mShouldConfirmCloseMessageAppear = shouldConfirmCloseMessageAppear;
        }

        @JavascriptInterface
        public void adComplete(int credits) {
            Intent intent = new Intent(Constants.ACTION_BRAND_CONNECT_AD_COMPLETE);
            intent.putExtra(Constants.KEY_ACTIVITY_DATA_ACTION, credits);
            sendBroadcast(intent);
        }

        /**
         * Displays a toolbar with buttons.
         */
        @JavascriptInterface
        public void showWebControls(String position, String color, String actionButton, String actionButtonText) {
            showWebControls(position, color, actionButton, actionButtonText, null, null);
        }

        /**
         * Displays a toolbar with buttons.
         */
        @JavascriptInterface
        public void showWebControls(String position, String color, String actionButton, String actionButtonText,
                String offerButtonText, String offerActionUrl) {

            final String toolbarColor = unstringifyNull(color);
            final String relativePosition = position;

            final String lActionButton = actionButton;
            final String lActionButtonText = actionButtonText;

            final String lOfferButtonText = offerButtonText;
            final String lButtonActionUrl = offerActionUrl;

            runOnUiThread(new Runnable() {
                public void run() {
                    // If the ToolBar already exists, remove it, and create new
                    // one.
                    if (mToolBar != null) {
                        mToolBar.setVisibility(View.GONE);
                        mContainer.removeView(mToolBar);
                    }

                    // Create the ToolBar layout.
                    mToolBar = new RelativeLayout(WebViewActivity.this);

                    // Views that are created programmatically don't have id.
                    mToolBar.setId(1111111);

                    // Sets the color to the ToolBar.
                    if (toolbarColor == null) {
                        mToolBar.setBackgroundColor(Color.parseColor("#AA000000"));
                    } else {
                        mToolBar.setBackgroundColor(Color.parseColor("#" + toolbarColor));
                    }

                    mToolBar.setVisibility(View.VISIBLE);

                    // Sets the toolbar's height, adds it's positions
                    // properties, and match the WebViw with it.
                    Resources r = getResources();
                    int height = (int) (TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 50,
                            r.getDisplayMetrics()));

                    RelativeLayout.LayoutParams toolBarLayoutParams = new RelativeLayout.LayoutParams(
                            LayoutParams.MATCH_PARENT, height);
                    RelativeLayout.LayoutParams webViewLayoutParams = new RelativeLayout.LayoutParams(
                            LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);

                    if (relativePosition.equalsIgnoreCase("bottom")) {
                        toolBarLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM, -1);
                        webViewLayoutParams.addRule(RelativeLayout.ABOVE, mToolBar.getId());
                    } else {
                        toolBarLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP, -1);
                        webViewLayoutParams.addRule(RelativeLayout.BELOW, mToolBar.getId());
                    }
                    mWebViewFrameContainer.setLayoutParams(webViewLayoutParams);
                    mToolBar.setLayoutParams(toolBarLayoutParams);

                    // Adds action button to ToolBar - either close or back
                    // actions are supported.
                    if (lActionButton != null && lActionButtonText != null
                            && (lActionButton.equalsIgnoreCase("close") || lActionButton.equalsIgnoreCase("back"))) {
                        RelativeLayout.LayoutParams actionButtonLayoutParams = new RelativeLayout.LayoutParams(
                                LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT);
                        actionButtonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
                        actionButtonLayoutParams.setMargins(5, 5, 0, 0);

                        Button actionButton = new Button(WebViewActivity.this);
                        actionButton.setLayoutParams(actionButtonLayoutParams);
                        actionButton.setText(decodeText(lActionButtonText));
                        if (lActionButton.equalsIgnoreCase("close")) {
                            if (mShouldConfirmCloseMessageAppear) {

                            }
                            actionButton.setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View v) {
                                    if (mShouldConfirmCloseMessageAppear) {
                                        showCloseConfirmDialog();
                                    } else {
                                        // Exits from the activity
                                        finish();
                                    }
                                }
                            });
                        } else if (lActionButton.equalsIgnoreCase("back")) {
                            actionButton.setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View v) {
                                    onBackPressed();
                                }
                            });
                        }

                        mToolBar.addView(actionButton);
                    }

                    // Adds offer button to ToolBar.
                    if (lOfferButtonText != null && lButtonActionUrl != null) {

                        RelativeLayout.LayoutParams offerButtonLayoutParams = new RelativeLayout.LayoutParams(
                                LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT);
                        offerButtonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
                        offerButtonLayoutParams.setMargins(0, 5, 5, 0);

                        Button offerButton = new Button(WebViewActivity.this);
                        offerButton.setLayoutParams(offerButtonLayoutParams);
                        offerButton.setText(decodeText(lOfferButtonText));
                        offerButton.setOnClickListener(new View.OnClickListener() {

                            @Override
                            public void onClick(View v) {
                                mWebView.loadUrl(decodeText(lButtonActionUrl));
                            }
                        });

                        mToolBar.addView(offerButton);
                    }

                    mContainer.addView(mToolBar);
                    mContainer.invalidate();
                }
            });
        }

        @JavascriptInterface
        public void hideWebControls() {
            runOnUiThread(new Runnable() {
                public void run() {
                    if (mToolBar != null) {
                        mContainer.removeView(mToolBar);
                        mContainer.invalidate();

                        // No need to the tool bar anymore, remove it's
                        // reference.
                        mToolBar = null;
                    }
                }
            });
        }

        /**
         * Calls to notify the application that there no more offers.
         */
        @JavascriptInterface
        public void noMoreOffers() {
            Intent intent = new Intent(Constants.ACTION_BRAND_CONNECT_NO_MORE_OFFERS);
            sendBroadcast(intent);
        }

        @JavascriptInterface
        public void __toast(String message) {
            Toast.makeText(WebViewActivity.this, message, Toast.LENGTH_LONG).show();
        }

        private String unstringifyNull(String string) {
            return (string != null && !string.equals("null")) ? string : null;
        }
    }
}
