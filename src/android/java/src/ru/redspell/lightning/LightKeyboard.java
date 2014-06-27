package ru.redspell.lightning;

import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.app.Activity;
import android.view.View;
import android.text.InputType;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.EditText;
import android.view.View.OnKeyListener;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.view.ViewGroup.LayoutParams;
import android.text.ClipboardManager;
import ru.redspell.lightning.utils.Log;

public class LightKeyboard {
	private static class OnChangeRunnable implements Runnable {
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

	// private static boolean kbrdVisible = false;
	private static ClipboardManager cbrdMngr;

	private static ClipboardManager getClipboardManager() {
		if (cbrdMngr == null) {
			cbrdMngr = (ClipboardManager)LightView.instance.activity.getSystemService(Context.CLIPBOARD_SERVICE);
		}

		return cbrdMngr;
	}

	public static void showKeyboard(final boolean visible, final int w, final int h, final String inittxt, final int onhide, final int onchange) {
		Log.d("LIGHTNING", "showKeyboard call");

		final LightView view = LightView.instance;
		
		view.getHandler().post(new Runnable() {
			public void run() {				
				final LightActivity activity = view.activity;
				final InputMethodManager imm = (InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE);
				final LightEditTextContainer letc;
				final LightEditText let;

				if (activity.viewGrp.getChildCount() == 2) {
					letc = (LightEditTextContainer)activity.viewGrp.findViewById(R.id.editor_container);
					let = (LightEditText)letc.findViewById(R.id.editor);
					let.setText(inittxt);
				} else {
					letc = (LightEditTextContainer)activity.getLayoutInflater().inflate(R.layout.editor, activity.viewGrp, false);
					let = (LightEditText)letc.findViewById(R.id.editor);
					final TextWatcher tw = new TextWatcher() {
						public void afterTextChanged(Editable s) {
							Log.d("LIGHTNING", "afterTextChanged " + s.toString());
						}

						public void beforeTextChanged(CharSequence s, int start, int count, int after) {
							Log.d("LIGHTNING", "beforeTextChanged " + s.toString());
						}

						public void onTextChanged(CharSequence s, int start, int before, int count) {
							Log.d("LIGHTNING", "onTextChanged " + s.toString());

							if (onchange > -1) {
								LightView.instance.queueEvent(new OnChangeRunnable(onchange, s.toString()));
							}						
						}
					};
					final LightEditText.OnKeyboardHideListener khl = new LightEditText.OnKeyboardHideListener() {
						public void onKeyboardHide(boolean backPressed) {
							Log.d("LIGHTNING", "LightTextEdit.OnKeyboardHideListener onKeyboardHide");

							let.removeTextChangedListener(tw);
							let.resetOnKeyboardHideListener();
							if (!backPressed) imm.hideSoftInputFromWindow(let.getWindowToken(), 0);
							activity.viewGrp.removeView(letc);


							LightView.instance.queueEvent(new OnHideRunnable(onchange, onhide, let.getText().toString()));	
							view.setEnabled(true);
						}
					};

					((android.widget.Button)letc.findViewById(R.id.editor_ok_bt)).setOnClickListener(new View.OnClickListener() {
						public void onClick(View view) {
							khl.onKeyboardHide(false);
						}
					});

					Log.d("LIGHTNING", "adding view");
					activity.viewGrp.addView(letc, visible ? 1 : 0);
					let.setOnKeyboardHideListener(khl);
					let.requestFocus();
					let.addTextChangedListener(tw);

					if (w > -1) let.setWidth(w);
					if (h > -1) let.setHeight(h);

					if (visible) view.setEnabled(false);					
				}

				imm.showSoftInput(let, InputMethodManager.SHOW_FORCED);
			}
		});
	}

	public static void hideKeyboard() {
		Log.d("LIGHTNING", "hideKeyboard");

		final LightView view = LightView.instance;

		view.getHandler().post(new Runnable() {
			public void run() {
				view.setEnabled(true);

				LightActivity activity = view.activity;
				View editor = activity.viewGrp.findViewById(R.id.editor);

				if (editor != null) {
					((InputMethodManager)activity.getSystemService(Context.INPUT_METHOD_SERVICE)).hideSoftInputFromWindow(editor.getWindowToken(), 0);
				}
			}
		});
	}

	public static void copyToClipboard(String txt) {
		getClipboardManager().setText(txt);
	}

	public static String pasteFromClipboard() {
		CharSequence cs = getClipboardManager().getText();

		return cs != null ? cs.toString() : null;
	}
}