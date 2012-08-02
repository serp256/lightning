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
