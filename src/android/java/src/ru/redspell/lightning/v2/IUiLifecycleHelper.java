package ru.redspell.lightning.v2;

import android.os.Bundle;
import android.content.Intent;

public interface IUiLifecycleHelper {
	void onCreate(Bundle savedInstanceState);
	void onResume();
	void onActivityResult(int requestCode, int resultCode, Intent data);
	void onSaveInstanceState(Bundle outState);
	void onPause();
	void onStop();
	void onDestroy();
}