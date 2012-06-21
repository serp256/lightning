package ru.redspell.lighttest;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import ru.redspell.lightning.LightView;
import android.util.Log;

public class LightTest extends Activity
{
	private LightView lightView;
	//private FrameLayout lightViewParent = null;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
			Log.d("LIGHTTEST","onCreate!!!");
			super.onCreate(savedInstanceState);
			setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
			//lightViewParent = new FrameLayout(this);
			lightView = new LightView(this);
			//lightViewParent.addView(lightView);
			Log.d("LIGHTTEST","view created");
			setContentView(lightView);
	}


	@Override
		protected void onPause() {
			Log.d("LIGHTNING","ON PAUSE");
			lightView.onPause();
			//lightView.setVisibility(View.GONE); 
			//lightViewParent.removeView(lightView); 
			super.onPause();
		}


	  @Override
			protected void onResume() {
				super.onResume();
				lightView.onResume();
			}

		@Override
			protected void onDestroy() {
				Log.d("LIGHTNING","ON DESTROY");
				lightView.onDestroy();
				super.onDestroy();
			}
		/*
		@Override 
			public void onWindowFocusChanged(boolean hasFocus) { 
				Log.d("LIGHTNING","onWindowFocusChanged");
				if (hasFocus && lightView != null ) { //&& lightView.getVisibility() == View.GONE) { 
					lightViewParent.addView(lightView); 
					//lightView.setVisibility(View.VISIBLE); 
				}
				super.onWindowFocusChanged(hasFocus); 
			}
		*/

		static {
			System.loadLibrary("test");
		}

}
