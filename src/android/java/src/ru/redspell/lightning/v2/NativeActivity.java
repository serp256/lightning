package ru.redspell.lightning.v2;

import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;

import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Iterator;

import ru.redspell.lightning.v2.IUiLifecycleHelper;

public class NativeActivity extends android.app.NativeActivity {
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();

	public FrameLayout viewGrp = null;
	public boolean isRunning = false;

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
		super.onStop();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onStop();
		}
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onDestroy();
		}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		Lightning.convertIntent(intent);
	}	
}