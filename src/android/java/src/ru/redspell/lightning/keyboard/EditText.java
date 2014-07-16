package ru.redspell.lightning.keyboard;

import android.content.Context;
import android.util.AttributeSet;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;

import ru.redspell.lightning.utils.Log;

public class EditText extends android.widget.EditText {
	public interface OnKeyboardHideListener {
		void onKeyboardHide(boolean backPressed);
	}

	protected OnKeyboardHideListener onKeyboardHideListener = null;

	public EditText(Context context) {
		super(context);
	}

	public EditText(Context context, AttributeSet attrs) {
		super(context, attrs);
	}

	public EditText(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
	}

	@Override
	public void onEditorAction (int actionId) {
		Log.d("LIGHTNING", "onEditorAction " + (new Integer(actionId)).toString());

		if (actionId == EditorInfo.IME_ACTION_DONE) {
			Log.d("LIGHTNING", "done");
			if (onKeyboardHideListener != null) onKeyboardHideListener.onKeyboardHide(false);
		}

		super.onEditorAction(actionId);
	}

	@Override
	public boolean onKeyPreIme(int keyCode, KeyEvent event) {
		Log.d("LIGHTNING", "onKeyPreIme " + (new Integer(keyCode).toString()));

		if (keyCode == KeyEvent.KEYCODE_BACK && onKeyboardHideListener != null) {
			Log.d("LIGHTNING", "back pressed");
			if (onKeyboardHideListener != null) onKeyboardHideListener.onKeyboardHide(true);
		}

		return super.onKeyUp(keyCode, event);
	}

	public void setOnKeyboardHideListener(OnKeyboardHideListener listener) {
		onKeyboardHideListener = listener;
	}

	public void resetOnKeyboardHideListener() {
		onKeyboardHideListener = null;
	}	
}