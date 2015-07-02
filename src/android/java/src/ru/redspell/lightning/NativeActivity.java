package ru.redspell.lightning;

import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;
import android.view.View;
import android.view.KeyEvent;
import android.widget.EditText;

import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Iterator;
import java.util.Timer;

import ru.redspell.lightning.IUiLifecycleHelper;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.keyboard.Keyboard;
import ru.redspell.lightning.notifications.Receiver;
import ru.redspell.lightning.download_service.LightDownloadService;

public class NativeActivity extends android.app.NativeActivity {
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();
	public static NativeActivity instance = null;
	private static Timer backgroundCallbackTimer = null;
	private static long backgroundCallbackDelay = -1;

	public boolean isRunning = false;

	public NativeActivity() {
		super();
		instance = this;
	}

	public static void addUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.add(helper);
	}

	public static void removeUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.remove(helper);
	}

	private void setImmersiveMode() {
		if (android.os.Build.VERSION.SDK_INT > 18) {
			getWindow().getDecorView().setSystemUiVisibility(
			View.SYSTEM_UI_FLAG_LAYOUT_STABLE
			| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
			| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_FULLSCREEN
			| View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
		}
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		Log.d("LIGHTNING", "onCreate call");
		Lightning.locale();
		super.onCreate(savedInstanceState);

		/*editText = new EditText(this);*/

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onCreate(savedInstanceState);
		}

		/* ugly workaround for determine is keyboard visible or not */
		final View view = getWindow().getDecorView();
		view.getViewTreeObserver().addOnGlobalLayoutListener(new android.view.ViewTreeObserver.OnGlobalLayoutListener() {
			public void onGlobalLayout() {
				if (isRunning) {
					android.graphics.Rect rect = new android.graphics.Rect();
					view.getWindowVisibleDisplayFrame(rect);
					/*Log.d("LIGHTNING", "RECT " + rect.toString());*/
					float displayHeight = (float)(rect.bottom - rect.top);
					float height = (float)view.getHeight();

/*					Log.d("LIGHTNING", "height " + height);
					Log.d("LIGHTNING", "displayHeight " + displayHeight);
					Log.d("LIGHTNING", "height / displayHeight " + (displayHeight / height));*/
					Keyboard.setVisible((displayHeight / height) < 0.8);
				}
			}
		});

		if (android.os.Build.VERSION.SDK_INT > 10) {
			view.setOnSystemUiVisibilityChangeListener(new View.OnSystemUiVisibilityChangeListener() {
				@Override
				public void onSystemUiVisibilityChange(int visibility) {
					if ((visibility & View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
						setImmersiveMode();
					}
				}
			});
		}
	}

	@Override
	public boolean dispatchKeyEvent(KeyEvent event) {
		if (Keyboard.visible()) {
			if (event.getAction() == KeyEvent.ACTION_DOWN) {
				Log.d("LIGHTNING", "event.getKeyCode() " + event.getKeyCode() + " " + KeyEvent.KEYCODE_DEL);

				switch (event.getKeyCode()) {
					case KeyEvent.KEYCODE_BACK:
					case KeyEvent.KEYCODE_ENTER:
						Keyboard.hide();
						return true;

					case KeyEvent.KEYCODE_DEL:
						/** this call is for some devices like huawei, motorola, asus transformer etc which skip backspace press for unknown reasons
							* but with this call backspace press is handled correctly
							*/
						Log.d("LIGHTNING", "Keyboard.textEdit.dispatchKeyEvent");
						Keyboard.textEdit.dispatchKeyEvent(event);
						return true;
				}

				Keyboard.textEdit.dispatchKeyEvent(event);
				return true;
			}
		}

		return super.dispatchKeyEvent(event);
	}

	@Override
	protected void onResume() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onResume");
		Receiver.appRunning = true;
		LightDownloadService.appRunning = true;
		LightDownloadService.needPush = false;
		isRunning = true;
		super.onResume();

		setImmersiveMode();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onResume();
		}

		if (backgroundCallbackTimer != null) {
			backgroundCallbackTimer.cancel();
			backgroundCallbackTimer = null;
		}
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "onActivityResult " + requestCode + " " + resultCode + " data " + data);
		super.onActivityResult(requestCode, resultCode, data);

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onActivityResult(requestCode, resultCode, data);
		}
	}

	@Override
	protected void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onSaveInstanceState(outState);
		}
	}

	private static class TimerTask extends java.util.TimerTask {
		public native void run();
	}

	@Override
	protected void onPause() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onPause");
		Receiver.appRunning = false;
		LightDownloadService.needPush = true;
		isRunning = false;
		super.onPause();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onPause();
		}

		if (backgroundCallbackDelay > 0) {
			backgroundCallbackTimer = new Timer();
			backgroundCallbackTimer.schedule(new TimerTask(), backgroundCallbackDelay);
		}
	}

	@Override
	protected void onStop() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onStop");
		LightDownloadService.appRunning = true;
		LightDownloadService.needPush = true;
		super.onStop();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onStop();
		}
	}

	@Override
	protected void onDestroy() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onDestroy");
		LightDownloadService.appRunning = false;
		LightDownloadService.needPush = true;
		super.onDestroy();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onDestroy();
		}
	}

	@Override
	public void onLowMemory() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onLowMemory");
		super.onLowMemory();
	}

	@Override
	public void onTrimMemory(int level) {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onTrimMemory");
		super.onTrimMemory(level);
	}

	@Override
	protected void onNewIntent(Intent intent) {
		Lightning.convertIntent(intent);
	}

	@Override
	public void onBackPressed() {
		Lightning.onBackPressed();
	}

	@Override
	public void onWindowFocusChanged(boolean hasFocus) {
		Log.d("LIGHTNING", "onWindowFocusChanged");
	    super.onWindowFocusChanged(hasFocus);

	    if (hasFocus) {
			setImmersiveMode();
		}
	}

	private class NativeRunnable implements Runnable {
		private int runnable;

		public NativeRunnable(int runnable) {
			this.runnable = runnable;
		}

		private native void run(int runnable);

		@Override
		public void run() {
			run(runnable);
		}
	}

	public void runOnUiThread(int runnable) {
		runOnUiThread(new NativeRunnable(runnable));
	}

	public static void setBackgroundCallbackDelay(long delay) {
		backgroundCallbackDelay = delay;
	}

	public static void resetBackgroundCallbackDelay() {
		backgroundCallbackDelay = -1;

		if (backgroundCallbackTimer != null) {
			backgroundCallbackTimer.cancel();
			backgroundCallbackTimer = null;
		}
	}
}
