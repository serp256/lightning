package ru.redspell.lighttest;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import ru.redspell.lightning.LightView;
import ru.redspell.lightning.utils.Log;

import android.content.Intent;
import com.facebook.android.*;
import com.facebook.android.Facebook.*;
import com.facebook.android.AsyncFacebookRunner.*;

import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.io.IOException;
import ru.redspell.lightning.LightActivity;

import android.os.Build;
import android.provider.Settings.Secure;
import android.provider.Settings;

import ru.redspell.lightning.LightNotifications;

public class LightTest extends LightActivity
{
	private LightView lightView;
	/*
    @Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		lightView.fb.fb.authorizeCallback(requestCode, resultCode, data);
	}
	*/
	//private FrameLayout lightViewParent = null;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		//setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
		Log.d("LIGHTNING", "BRAND=" + Build.BRAND);
		Log.d("LIGHTNING", "DEVICE=" + Build.DEVICE);
		Log.d("LIGHTNING", "DISPLAY=" + Build.DISPLAY);
		Log.d("LIGHTNING", "HARDWARE=" + Build.HARDWARE);
		Log.d("LIGHTNING", "MANUFACTURER=" + Build.MANUFACTURER);
//		Log.d("LIGHTNING", "SERIAL=" + Build.SERIAL);
		Log.d("LIGHTNING", "USER=" + Build.USER);
		Log.d("LIGHTNING", "MODEL=" + Build.MODEL);
		Log.d("LIGHTNING", "PRODUCT=" + Build.PRODUCT);


		Log.d("LIGHTNING", "ANDROID_ID=" + Secure.ANDROID_ID);
		String deviceId = Settings.System.getString(getContentResolver(),Secure.ANDROID_ID);
		Log.d("LIGHTNING", "ANDROID_ID=" + deviceId);

		LightNotifications.groupNotifications = true;
		LightActivity.enableLocalExpansions();
	}

	static {
		System.loadLibrary("test");
	}
}
