package ru.redspell.lighttest;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import ru.redspell.lightning.LightView;
import android.util.Log;

import android.content.Intent;
import com.facebook.android.*;
import com.facebook.android.Facebook.*;
import com.facebook.android.AsyncFacebookRunner.*;

import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.io.IOException;
import ru.redspell.lightning.LightActivity;



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
		setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
	}

	static {
		System.loadLibrary("test");
	}
}
