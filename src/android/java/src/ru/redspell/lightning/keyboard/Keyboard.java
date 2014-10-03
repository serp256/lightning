package ru.redspell.lightning.keyboard;

import android.view.WindowManager;
import ru.redspell.lightning.Lightning;
import android.view.inputmethod.InputMethodManager;
import android.text.ClipboardManager;
import android.content.Context;
import android.os.ResultReceiver;
import android.os.Bundle;
import android.util.Log;

public class Keyboard {
	public static boolean visible = false;

	private static InputMethodManager inputMethodManager = null;

	private static InputMethodManager inputMethodManager() {
		if (inputMethodManager == null) {
			inputMethodManager = (InputMethodManager)Lightning.activity.getSystemService(Context.INPUT_METHOD_SERVICE);
		}

		return inputMethodManager;
	}

	public static void show(String initText) {
		Lightning.activity.setKeyboardText(initText);
		inputMethodManager().showSoftInput(Lightning.activity.getWindow().getDecorView(), InputMethodManager.SHOW_FORCED);
	}

	public static void hide() {
		inputMethodManager().hideSoftInputFromWindow(Lightning.activity.getWindow().getDecorView().getWindowToken(), 0);
	}

	public static boolean visible() {
		return visible;
	}

	public native static void onHide(String text);

	public native static void onChange(String text);

	public static void setVisible(boolean visible) {
		if (Keyboard.visible != visible) {
			if (Keyboard.visible) {
				onHide(Lightning.activity.keyboardText());
				Lightning.activity.setKeyboardText("");
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
