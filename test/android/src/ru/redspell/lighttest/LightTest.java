package ru.redspell.lighttest;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.os.Bundle;
import ru.redspell.lightning.LightView;
import android.util.Log;

public class LightTest extends Activity
{
	private LightView lightView;
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState)
	{
			Log.d("LIGHTTEST","onCreate!!!");
			super.onCreate(savedInstanceState);
			setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
			lightView = new LightView(this);
			Log.d("LIGHTTEST","view created");
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

		static {
			System.loadLibrary("test");
		}

}
