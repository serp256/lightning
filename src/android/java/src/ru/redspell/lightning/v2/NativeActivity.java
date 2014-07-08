package ru.redspell.lightning.v2;

import android.content.Intent;
import android.os.Bundle;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.Iterator;
import ru.redspell.lightning.IUiLifecycleHelper;

public class NativeActivity extends android.app.NativeActivity {
	private static CopyOnWriteArrayList<IUiLifecycleHelper> uiLfcclHlprs = new CopyOnWriteArrayList();

	public static void addUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.add(helper);
	}

	public static void removeUiLifecycleHelper(IUiLifecycleHelper helper) {
		uiLfcclHlprs.remove(helper);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Iterator<IUiLifecycleHelper> iter = uiLfcclHlprs.iterator();
		while (iter.hasNext()) {
			IUiLifecycleHelper h = iter.next();
			h.onCreate(savedInstanceState);
		}
	}

	@Override
	protected void onResume() {
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
}