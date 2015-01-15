package ru.redspell.lightning.keyboard;

import android.text.InputType;
import android.view.inputmethod.EditorInfo;
import android.widget.FrameLayout;
import android.widget.EditText;
import android.view.WindowManager;
import ru.redspell.lightning.Lightning;
import android.view.inputmethod.InputMethodManager;
import android.text.ClipboardManager;
import android.content.Context;
import android.os.ResultReceiver;
import android.os.Bundle;
import android.util.Log;
import android.text.InputFilter;
import android.text.Spanned;

public class Keyboard {
	public static boolean visible = false;
	public static EditText textEdit = null;

	private static InputMethodManager inputMethodManager = null;

	private static InputMethodManager inputMethodManager() {
		if (inputMethodManager == null) {
			inputMethodManager = (InputMethodManager)Lightning.activity.getSystemService(Context.INPUT_METHOD_SERVICE);
		}

		return inputMethodManager;
	}

	public static void show(final String initText, final String filter) {
		Log.d("LIGHTNING", "show keyboard");

		Lightning.activity.runOnUiThread(new Runnable(){
		    @Override
		    public void run() {
					if (textEdit == null) {
						textEdit = new EditText(Lightning.activity);
						textEdit.setImeOptions(EditorInfo.IME_ACTION_DONE | EditorInfo.IME_FLAG_NO_EXTRACT_UI);
						textEdit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_NORMAL | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
						textEdit.setSingleLine(true);

						if (filter != null) {
							InputFilter[] filters = {
								new InputFilter() {
									@Override
									public CharSequence filter(CharSequence source, int start, int end, Spanned dest, int dstart, int dend) {
										return source.toString().replaceAll("[^" + filter + "]", "");
									}
								}
							};

							textEdit.setFilters(filters);
						}

						FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
						textEdit.setLayoutParams(layoutParams);
						Lightning.activity.addContentView(textEdit, layoutParams);
						textEdit.addTextChangedListener(new android.text.TextWatcher() {
							@Override
							public void afterTextChanged(android.text.Editable s) {
								//Log.d("LIGHTNING", "afterTextChanged");
							}

							@Override
							public void beforeTextChanged(CharSequence s, int start, int count, int after) {
								//Log.d("LIGHTNING", "beforeTextChanged");
							}

							@Override
							public void onTextChanged(CharSequence s, int start, int before, int count) {
								//Log.d("LIGHTNING", "onTextChanged");
								onChange(textEdit.getText().toString());
							}
						});
					}

					String _initText = initText == null ? "" : initText;
					textEdit.requestFocus();
					textEdit.setText(_initText);
					textEdit.setSelection(_initText.length());
					inputMethodManager().showSoftInput(textEdit, 0);
			}
		});

		Log.d("LIGHTNING", "done");


/*		Lightning.activity.setKeyboardText(initText);
		inputMethodManager().showSoftInput(Lightning.activity.getWindow().getDecorView(), InputMethodManager.SHOW_FORCED);*/
	}

	public static void hide() {
		if (textEdit != null) {
			inputMethodManager().hideSoftInputFromWindow(textEdit.getWindowToken(), 0);
		}
	}

	public static void clean() {
		if (textEdit != null) {
			textEdit.setText ("");
		}
	}
	public static boolean visible() {
		return visible;
	}

	public native static void onHide(String text);

	public native static void onChange(String text);

	public static void setVisible(boolean visible) {
		if (textEdit == null) return;
		if (Keyboard.visible != visible) {
			if (Keyboard.visible) {
				onHide(textEdit.getText().toString());
				Lightning.activity.onWindowFocusChanged(true);
				textEdit.setText("");
			}
			Keyboard.visible = visible;
		}
	}

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

	public static void copyToClipboard(final String text) {
		runWhenClipboardReady(new Runnable() {
			public void run() {
			  clipboardManager.setText(text);
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
