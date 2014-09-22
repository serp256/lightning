package ru.redspell.lightning;

import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;

import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Iterator;

import ru.redspell.lightning.IUiLifecycleHelper;

public class NativeActivity extends android.app.NativeActivity {
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();
	public static NativeActivity instance = null;

	public FrameLayout viewGrp = null;
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

		viewGrp = new FrameLayout(this);
		addContentView(viewGrp, new android.view.ViewGroup.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.MATCH_PARENT));

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onCreate(savedInstanceState);
		}
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
