package ru.redspell.lightning.keyboard;

import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.app.Activity;
import android.view.View;
import android.text.InputType;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View.OnKeyListener;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.view.ViewGroup.LayoutParams;
import android.text.ClipboardManager;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.NativeActivity;
import ru.redspell.lightning.utils.Log;

public class Keyboard {
/*	private static class OnChangeRunnable implements Runnable {
		private int cb;
		private String txt;

		public OnChangeRunnable(int cb, String txt) {
			this.cb = cb;
			this.txt = txt;
		}

		native public void run();
	}

	private static class OnHideRunnable implements Runnable  {
		private int changeCb;
		private int hideCb;
		private String txt;

		public OnHideRunnable(int changeCb, int hideCb, String txt) {
			this.changeCb = changeCb;
			this.hideCb = hideCb;
			this.txt  = txt;
		}

		native public void run();
	}
*/
	private static native void onChange(String text);
	private static native void onHide(String text);

	private static ClipboardManager clipboardManager = null;

	private static void runWhenClipboardReady(final Runnable r) {
		if (clipboardManager == null) {
			Lightning.activity.runOnUiThread(new Runnable() {
				public void run() {
					clipboardManager = (ClipboardManager)Lightning.activity.getSystemService(Context.CLIPBOARD_SERVICE);
					r.run();
				}
			});
		} else {
			r.run();
		}
	}

	public static void showKeyboard(final boolean visible, final int w, final int h, final String inittxt) {
		Log.d("LIGHTNING", "showKeyboard call");

		final NativeActivity activity = Lightning.activity;

		activity.runOnUiThread(new Runnable() {
			public void run() {
				final InputMethodManager imm = (InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE);
				final EditTextContainer letc;
				final EditText let;

				Log.d("LIGHTNING", "activity.viewGrp.getChildCount() " + activity.viewGrp.getChildCount() + " " + inittxt);

				if (activity.viewGrp.getChildCount() == 1) {
					Log.d("LIGHTNING", "if1");
					letc = (EditTextContainer)activity.viewGrp.findViewById(ru.redspell.lightning.R.id.editor_container);
					let = (EditText)letc.findViewById(ru.redspell.lightning.R.id.editor);
					Log.d("LIGHTNING", "if2");
				} else {
					Log.d("LIGHTNING", "else1");
					letc = (EditTextContainer)activity.getLayoutInflater().inflate(ru.redspell.lightning.R.layout.editor, activity.viewGrp, false);
					let = (EditText)letc.findViewById(ru.redspell.lightning.R.id.editor);
					final TextWatcher tw = new TextWatcher() {
						public void afterTextChanged(Editable s) {
							Log.d("LIGHTNING", "afterTextChanged " + s.toString());
						}

						public void beforeTextChanged(CharSequence s, int start, int count, int after) {
							Log.d("LIGHTNING", "beforeTextChanged " + s.toString());
						}

						public void onTextChanged(CharSequence s, int start, int before, int count) {
							Log.d("LIGHTNING", "onTextChanged " + s.toString());

							onChange(s.toString());
						}
					};
					final EditText.OnKeyboardHideListener khl = new EditText.OnKeyboardHideListener() {
						public void onKeyboardHide(boolean backPressed) {
							Log.d("LIGHTNING", "LightTextEdit.OnKeyboardHideListener onKeyboardHide");

							// let.removeTextChangedListener(tw);
							// let.resetOnKeyboardHideListener();
							if (!backPressed) imm.hideSoftInputFromWindow(let.getWindowToken(), 0);
							// activity.viewGrp.removeView(letc);

							onHide(let.getText().toString());
							Lightning.enableTouches();
						}
					};

					((android.widget.Button)letc.findViewById(ru.redspell.lightning.R.id.editor_ok_bt)).setOnClickListener(new View.OnClickListener() {
						public void onClick(View view) {
							khl.onKeyboardHide(false);
						}
					});

					let.setOnKeyboardHideListener(khl);
					let.addTextChangedListener(tw);
					activity.viewGrp.addView(letc);
				}

				letc.setVisibility(visible ? View.INVISIBLE : View.VISIBLE);
				let.requestFocus();
				let.setText(inittxt);
				let.setSelection(inittxt.length());

				if (w > -1) let.setWidth(w);
				if (h > -1) let.setHeight(h);

				if (visible) Lightning.disableTouches();
				imm.showSoftInput(let, InputMethodManager.SHOW_FORCED);
			}
		});
	}

	public static void hideKeyboard() {
		Log.d("LIGHTNING", "hideKeyboard");

		final NativeActivity activity = Lightning.activity;

		activity.runOnUiThread(new Runnable() {
			public void run() {
				Lightning.enableTouches();
				View editor = activity.viewGrp.findViewById(ru.redspell.lightning.R.id.editor);

				if (editor != null) {
					((InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(editor.getWindowToken(), 0);
				}
			}
		});
	}

	public static void copyToClipboard(final String txt) {
		runWhenClipboardReady(new Runnable() {
			public void run() {
				clipboardManager.setText(txt);
			}
		});
	}

	private static class PasteRunnable implements Runnable {
		private int callback;

		public PasteRunnable(int callback) {
			this.callback = callback;
		}

		private native void nativeRun(int callback, String text);

		public void run() {
			CharSequence cs = clipboardManager.getText();
			nativeRun(callback, cs != null ? cs.toString() : null);
		}
	}

	public static void pasteFromClipboard(int callback) {
		runWhenClipboardReady(new PasteRunnable(callback));
	}
}
