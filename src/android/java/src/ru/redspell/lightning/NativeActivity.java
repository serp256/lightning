package ru.redspell.lightning;

import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;
import android.view.View;
import android.view.KeyEvent;
import android.widget.EditText;

import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Iterator;

import ru.redspell.lightning.IUiLifecycleHelper;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.keyboard.Keyboard;

public class NativeActivity extends android.app.NativeActivity {
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();
	public static NativeActivity instance = null;

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

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		/*editText = new EditText(this);*/

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onCreate(savedInstanceState);
		}

		/* ugly workaround for determine is keyboard visible or not */
		final View view = getWindow().getDecorView();
		getWindow().getDecorView().getViewTreeObserver().addOnGlobalLayoutListener(new android.view.ViewTreeObserver.OnGlobalLayoutListener() {
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
	}

	@Override
	public boolean dispatchKeyEvent(KeyEvent event) {
		if (Keyboard.visible()) {
			if (event.getAction() == KeyEvent.ACTION_UP) {
				Log.d("LIGHTNING", "event.getKeyCode() " + event.getKeyCode());

				switch (event.getKeyCode()) {
					case KeyEvent.KEYCODE_BACK:
					case KeyEvent.KEYCODE_ENTER:
						Keyboard.hide();
						return true;

					/** this call is for some devices like huawei, motorola, asus transformer etc which skip backspace press for unknown reasons
						* but with this call backspace press is handled correctly
						*/

/*					case KeyEvent.KEYCODE_DEL:

						return true;*/
				}
			}

			Keyboard.textEdit.dispatchKeyEvent(event);
		}

		return super.dispatchKeyEvent(event);
	}

	@Override
	protected void onResume() {
		isRunning = true;
		super.onResume();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onResume();
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

	@Override
	protected void onPause() {
		isRunning = false;
		super.onPause();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onPause();
		}
	}

	@Override
	protected void onStop() {
		ru.redspell.lightning.utils.Log.d("LIGHTNING", "native activity onStop");
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
}
