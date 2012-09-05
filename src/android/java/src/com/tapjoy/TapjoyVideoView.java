// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

import java.util.Timer;
import java.util.TimerTask;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnErrorListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.view.KeyEvent;
import android.view.ViewGroup.LayoutParams;
import android.view.Window;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.VideoView;


public class TapjoyVideoView extends Activity implements OnCompletionListener, OnErrorListener, OnPreparedListener
{
	private VideoView videoView = null;
	private String videoPath = null;
	private TextView overlayText = null;
	private String webviewURL = null;

	private RelativeLayout relativeLayout;
	private WebView webView;
	private Bitmap watermark;
	
	Dialog dialog;
	Timer timer = null;

	private static boolean videoError = false;
	private static boolean streamingVideo = false;
	private static TapjoyVideoObject videoData;
	
	// Handle activity termination/resume.
	private boolean dialogShowing = false;
	private static final String BUNDLE_DIALOG_SHOWING = "dialog_showing";
	private static final String BUNDLE_SEEK_TIME = "seek_time";
	
	private boolean sendClick = false;
	private boolean clickRequestSuccess = false;													// Whether the click request was successful or not (sent when video starts).
	private boolean allowBackKey = false;															// Whether to allow the BACK key to traverse to the previous activity.
	private int timeRemaining = 0;																	// Time remaining on video for textview.
	private int seekTime = 0;																		// Time to seek to if there is a pause/resume on the video.
	
	private static final int DIALOG_WARNING_ID = 0;
	private static final String videoWillResumeText = "";
	private static final String videoSecondsText = " seconds";
	
	private ImageView tapjoyImage;																	// Tapjoy watermark image shown on bottom right while video is playing.
	
	int deviceScreenDensity;
	int deviceScreenLayoutSize;

	final String TAPJOY_VIDEO = "VIDEO";

	// Need handler for callbacks to the UI thread
	final Handler mHandler = new Handler();
	
	static int textSize = 16;
	
	
	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		TapjoyLog.i(TAPJOY_VIDEO, "onCreate");
		super.onCreate(savedInstanceState);
		
		if (savedInstanceState != null)
		{
			TapjoyLog.i(TAPJOY_VIDEO, "*** Loading saved data from bundle ***");
			seekTime = savedInstanceState.getInt(BUNDLE_SEEK_TIME);
			dialogShowing = savedInstanceState.getBoolean(BUNDLE_DIALOG_SHOWING);
		}
		
		TapjoyLog.i(TAPJOY_VIDEO, "dialogShowing: " + dialogShowing + ", seekTime: " + seekTime);
		
		sendClick = true;
		streamingVideo = false;
		
		// Something went wrong?  break out.
		if (TapjoyVideo.getInstance() == null)
		{
			TapjoyLog.i(TAPJOY_VIDEO, "null video");
			finish();
			return;
		}
		
		videoData = TapjoyVideo.getInstance().getCurrentVideoData();
		videoPath = videoData.dataLocation;
		webviewURL = videoData.webviewURL;
		
		// No local video file, so stream.
		if (videoPath == null || videoPath.length() == 0)
		{
			TapjoyLog.i(TAPJOY_VIDEO, "no cached video, try streaming video at location: " + videoData.videoURL);
			videoPath = videoData.videoURL;
			streamingVideo = true;
		}
		
		TapjoyLog.i(TAPJOY_VIDEO, "videoPath: " + videoPath);
		
		requestWindowFeature(Window.FEATURE_NO_TITLE);

		relativeLayout = new RelativeLayout(this);
		RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
		relativeLayout.setLayoutParams(params);
		
		setContentView(relativeLayout);
		
		// Only allow for android-4 or greater.
		if (Integer.parseInt(android.os.Build.VERSION.SDK) > 3) 
		{
			TapjoyDisplayMetricsUtil displayMetricsUtil = new TapjoyDisplayMetricsUtil(this);
			
			deviceScreenLayoutSize = displayMetricsUtil.getScreenLayoutSize();
			
			TapjoyLog.i(TAPJOY_VIDEO, "deviceScreenLayoutSize: " + deviceScreenLayoutSize);
			
			// Resize for tablets.
			/*
			if (deviceScreenLayoutSize == Configuration.SCREENLAYOUT_SIZE_XLARGE)
			{
				textSize = 32;
			}
			*/
		}
		
		TapjoyLog.i(TAPJOY_VIDEO, "textSize: " + textSize);
		
		initVideoView();
		
		TapjoyLog.i(TAPJOY_VIDEO, "onCreate DONE");
	}

	@Override
	protected void onPause()
	{
		super.onPause();
		
		// If the video is playing, store the seek time so we can resume to it.
		if (videoView.isPlaying())
		{
			TapjoyLog.i(TAPJOY_VIDEO, "onPause");
			seekTime = videoView.getCurrentPosition();
			TapjoyLog.i(TAPJOY_VIDEO, "seekTime: " + seekTime);
		}
	}
	
	
	@Override
	protected void onResume()
	{
		TapjoyLog.i(TAPJOY_VIDEO, "onResume");
		super.onResume();
		
		// Set orientation to landscape.
		setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
		
		// The video was interrupted, so resume where it left off at.
		if (seekTime > 0)
		{
			TapjoyLog.i(TAPJOY_VIDEO, "seekTime: " + seekTime);
			
			videoView.seekTo(seekTime);
			
			// If the dialog is not showing, resume video playback.
			if (dialogShowing == false || dialog == null || dialog.isShowing() == false)
				videoView.start();
		}
	}
	

	@Override
	protected void onSaveInstanceState (Bundle outState)
	{
		super.onSaveInstanceState(outState);
		
		TapjoyLog.i(TAPJOY_VIDEO, "*** onSaveInstanceState ***");
		TapjoyLog.i(TAPJOY_VIDEO, "dialogShowing: " + dialogShowing + ", seekTime: " + seekTime);
		outState.putBoolean(BUNDLE_DIALOG_SHOWING, dialogShowing);
		outState.putInt(BUNDLE_SEEK_TIME, seekTime);
	}
	
	
	@Override
	public void onWindowFocusChanged(boolean hasFocus)
	{
		TapjoyLog.i(TAPJOY_VIDEO, "onWindowFocusChanged");
		super.onWindowFocusChanged(hasFocus);
	}
	
	
	private void initVideoView()
	{
		relativeLayout.removeAllViews();
		relativeLayout.setBackgroundColor(0xFF000000);
		
		if (videoView == null && overlayText == null)
		{
			//----------------------------------------
			// TAPJOY Watermark
			//----------------------------------------
			tapjoyImage = new ImageView(this);
			
			if (watermark == null)
			{
				// Cached in file ssytem.
				if (TapjoyConnectCore.isVideoCacheEnabled())
					watermark = BitmapFactory.decodeFile(TapjoyVideo.imageTapjoyLocation);
				// Uncached, stored as bitmap.
				else
					watermark = TapjoyVideo.watermark;
			}
			
			if (watermark != null)
				tapjoyImage.setImageBitmap(watermark);
			
			RelativeLayout.LayoutParams imageParams = new RelativeLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
			imageParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
			imageParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
			tapjoyImage.setLayoutParams(imageParams);
			
			//----------------------------------------
			// VIDEO VIEW
			//----------------------------------------
			videoView = new VideoView(this);
			videoView.setOnCompletionListener(this);
			videoView.setOnErrorListener(this);
			videoView.setOnPreparedListener(this);
			
			if (streamingVideo)
			{
				TapjoyLog.i(TAPJOY_VIDEO, "streaming video: " + videoPath);
				videoView.setVideoURI(Uri.parse(videoPath));
			}
			else
			{
				TapjoyLog.i(TAPJOY_VIDEO, "cached video: " + videoPath);
				videoView.setVideoPath(videoPath);
			}
			
			RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
			layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
			videoView.setLayoutParams(layoutParams);
			
			//----------------------------------------
			// X SECONDS TEXTVIEW
			//----------------------------------------
			timeRemaining = videoView.getDuration()/1000;
	
			TapjoyLog.i(TAPJOY_VIDEO, "videoView.getDuration(): " + videoView.getDuration());
			TapjoyLog.i(TAPJOY_VIDEO, "timeRemaining: " + timeRemaining);
			
			overlayText = new TextView(this);
			overlayText.setTextSize(textSize);
			overlayText.setTypeface(Typeface.create("default", Typeface.BOLD), Typeface.BOLD);
	
			RelativeLayout.LayoutParams textParams = new RelativeLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
			textParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
			overlayText.setLayoutParams(textParams);
		}
		
		startVideo();
		
		relativeLayout.addView(videoView);
		relativeLayout.addView(tapjoyImage);
		relativeLayout.addView(overlayText);
	}
	
	
	private void initVideoCompletionScreen()
	{
		webView = new WebView(this);
		webView.setWebViewClient(new WebViewClient()
			{
				/**
				 * When any user hits any url from tapjoy custom view then this function is called before opening any user.
				 */
				public boolean shouldOverrideUrlLoading(WebView view, String url)
				{
					TapjoyLog.i(TAPJOY_VIDEO, "URL = ["+url+"]");
					
					// Show the offer wall.
					if (url.contains("offer_wall"))
					{
						TapjoyLog.i(TAPJOY_VIDEO, "back to offers");
						finish();
					}
					else
					// Replays the video.
					if (url.contains("tjvideo"))
					{
						TapjoyLog.i(TAPJOY_VIDEO, "replay");
						initVideoView();
					}
					else
					// Keep redirecting URLs in the webview.
					if (url.contains(TapjoyConstants.TJC_BASE_REDIRECT_DOMAIN))
					{
						TapjoyLog.i(TAPJOY_VIDEO, "Open redirecting URL = ["+url+"]");
						view.loadUrl(url);
					}
					else
					// Open all other items in a new window.
					{
						TapjoyLog.i(TAPJOY_VIDEO, "Opening URL in new browser = ["+url+"]");
						Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
						startActivity(intent);
					}
					
					return true;
				}
			});
		
		WebSettings webSettings = webView.getSettings();
		webSettings.setJavaScriptEnabled(true);
		
		webView.loadUrl(webviewURL);
	}
	
	
	private void showVideoCompletionScreen()
	{
		relativeLayout.removeAllViews();
		relativeLayout.addView(webView, LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT);
	}
	
    
	/**
	 * Plays the video.
	 */
	private void startVideo()
	{
		videoView.requestFocus();
		
		// On Activity termination, if dialog was previously showing, don't start the video yet.
		if (dialogShowing)
		{
			videoView.seekTo(seekTime);
			TapjoyLog.i(TAPJOY_VIDEO, "dialog is showing -- don't start");
		}
		else
		{
			TapjoyLog.i(TAPJOY_VIDEO, "start");
			videoView.seekTo(0);
			videoView.start();
		}
		
		// Cancel the timer if it's active for some reason.
		if (timer != null)
		{
			timer.cancel();
		}
		
		// This timer is used to update the remaining time text.
		timer = new Timer();
		timer.schedule(new RemainingTime(), 500, 100);
		
		// Init the video completion screen now so it'll be ready when the video is done.
		initVideoCompletionScreen();
		
		// Reset flag.
		clickRequestSuccess = false;
		
		// Send a click if this is the first time.  Don't send clicks on replay.
		if (sendClick)
		{
			new Thread(new Runnable()
			{
				@Override
				public void run()
				{
					TapjoyLog.i(TAPJOY_VIDEO, "SENDING CLICK...");
					
					String response = new TapjoyURLConnection().connectToURL(videoData.clickURL);
					
					if (response != null && response.contains("OK"))
					{
						TapjoyLog.i(TAPJOY_VIDEO, "CLICK REQUEST SUCCESS!");
						clickRequestSuccess = true;
					}
				}
			}).start();
			
			sendClick = false;
		}
	}


	/**
	 * Returns remaining time of video.
	 * @return								Video time remaining, in seconds.
	 */
	private int getRemainingVideoTime()
	{
		int timeRemaining = (videoView.getDuration() - videoView.getCurrentPosition())/1000;

		if (timeRemaining < 0)
			timeRemaining = 0;

		return timeRemaining;
	}


	/**
	 * TimerTask to update the remaining time text overlay.
	 */
	private class RemainingTime extends TimerTask
	{
		public void run()
		{
			// We must use a handler since we cannot update UI elements from a different thread.
			mHandler.post(mUpdateResults);
		}
	}


	// Create runnable for posting
	final Runnable mUpdateResults = new Runnable() 
	{
		public void run() 
		{
			// Update text onscreen.
			overlayText.setText(videoWillResumeText + getRemainingVideoTime() + videoSecondsText);
		}
	};


	//--------------------------------------------------------------------------------
	// VIDEO LISTENERS
	//--------------------------------------------------------------------------------
	@Override
	public void onPrepared(MediaPlayer mp)
	{
		TapjoyLog.i(TAPJOY_VIDEO, "onPrepared");
	}


	@Override
	public boolean onError(MediaPlayer mp, int what, int extra)
	{
		videoError = true;
		TapjoyLog.i(TAPJOY_VIDEO, "onError");
		
		TapjoyVideo.getVideoNotifier().videoError(TapjoyVideoStatus.STATUS_UNABLE_TO_PLAY_VIDEO);
		allowBackKey = true;
		
		if (timer != null)
			timer.cancel();
		
		return false;
	}


	@Override
	public void onCompletion(MediaPlayer mp)
	{
		TapjoyLog.i(TAPJOY_VIDEO, "onCompletion");
		
		if (timer != null)
			timer.cancel();
		
		showVideoCompletionScreen();
		
		if (videoError == false)
		{
			//TapjoyVideo.getInstance().videoCompleted(videoPath);
			TapjoyVideo.getVideoNotifier().videoComplete();
			
			new Thread(new Runnable()
			{
				@Override
				public void run()
				{
					if (clickRequestSuccess)
						TapjoyConnectCore.getInstance().actionComplete(videoData.offerID);
				}
			}).start();
			
		}
		
		videoError = false;
		allowBackKey = true;
	}


	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event)
	{
		if ((keyCode == KeyEvent.KEYCODE_BACK))
		{
			// If the video is playing for the first time, don't allow interruption.
			if (allowBackKey == false)
			{
				// Prevent activity termination.
				// Show prompt whether to end video or not.
				seekTime = videoView.getCurrentPosition();
				videoView.pause();
				
				dialogShowing = true;
				showDialog(DIALOG_WARNING_ID);
				
				TapjoyLog.i(TAPJOY_VIDEO, "PAUSE VIDEO time: " + seekTime);
				TapjoyLog.i(TAPJOY_VIDEO, "currentPosition: " + videoView.getCurrentPosition());
				TapjoyLog.i(TAPJOY_VIDEO, "duration: " + videoView.getDuration() + ", elapsed: " + (videoView.getDuration() - videoView.getCurrentPosition()));
				return true;
			}
			// Video has already played once.
			else
			{
				// If the video is RE-playing, stop it and show the UI.
				if (videoView.isPlaying())
				{
					videoView.stopPlayback();
					showVideoCompletionScreen();
					
					if (timer != null)
						timer.cancel();
					
					return true;
				}
			}
		}

		return super.onKeyDown(keyCode, event);
	}
	
	
	protected Dialog onCreateDialog(int id)
	{
		TapjoyLog.i(TAPJOY_VIDEO, "dialog onCreateDialog");
		
		// Weird issue on Activity resuming when it was killed.
		if (dialogShowing == false)
			return dialog;
		
		//Dialog dialog;
		switch (id)
		{
			case DIALOG_WARNING_ID:
				dialog = new AlertDialog.Builder(this).setTitle("Cancel Video?").setMessage("Currency will not be awarded, are you sure you want to cancel the video?").
						setNegativeButton("End", new DialogInterface.OnClickListener()
						{
							// Terminate this activity.
							public void onClick(DialogInterface dialog, int whichButton)
							{
								finish();
							}
						}).setPositiveButton("Resume", new DialogInterface.OnClickListener()
						{
							// Resume the video.
							public void onClick(DialogInterface dialog, int whichButton)
							{
								dialog.dismiss();
								
								videoView.seekTo(seekTime);
								videoView.start();
								
								dialogShowing = false;
								
								TapjoyLog.i(TAPJOY_VIDEO, "RESUME VIDEO time: " + seekTime);
								TapjoyLog.i(TAPJOY_VIDEO, "currentPosition: " + videoView.getCurrentPosition());
								TapjoyLog.i(TAPJOY_VIDEO, "duration: " + videoView.getDuration() + ", elapsed: " + (videoView.getDuration() - videoView.getCurrentPosition()));
							}
						}).create();
				
				// Handle the BACK key in this Activity.
				dialog.setOnCancelListener(new DialogInterface.OnCancelListener()
				{
					@Override
					public void onCancel(DialogInterface dialog)
					{
						TapjoyLog.i(TAPJOY_VIDEO, "dialog onCancel");
						
						// Resume playback and dismiss dialog.
						dialog.dismiss();
						videoView.seekTo(seekTime);
						videoView.start();
						
						dialogShowing = false;
					}
				});
				dialog.show();
				dialogShowing = true;
				break;
			default:
				dialog = null;
		}
		return dialog;
	}
}