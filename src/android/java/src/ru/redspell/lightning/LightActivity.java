package ru.redspell.lightning;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import ru.redspell.lightning.LightView;
import android.util.Log;
import android.view.WindowManager;
import android.view.Window;

public class LightActivity extends Activity
{
	private LightView lightView;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		//setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
		lightView = new LightView(this);
		setContentView(lightView);
	}


	@Override
		protected void onPause() {
			super.onPause();
			lightView.onPause();
		}


	@Override
		protected void onResume() {
			super.onResume();
			lightView.onResume();
		}

	@Override
	public void onBackPressed() {
		lightView.onBackButton ();
	}

	@Override
	protected void onDestroy() {
		lightView.onDestroy();
		super.onDestroy();
	}	

}
