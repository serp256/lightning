package ru.redspell.lightning;

import android.media.MediaPlayer;
import java.util.ArrayList;
import java.util.Iterator;

public class LightMediaPlayer extends MediaPlayer {
	private static ArrayList<LightMediaPlayer> instances;
	private static ArrayList<LightMediaPlayer> paused;

	private class CamlCallbackCompleteListener implements MediaPlayer.OnCompletionListener {
		private int camlCb;

		public CamlCallbackCompleteListener(int cb) {
			camlCb = cb;
		}

		public native void onCompletion(MediaPlayer mp);
	}

	public void start(int cb) {
		setOnCompletionListener(new CamlCallbackCompleteListener(cb));
		start();
	}

	public LightMediaPlayer() {
		super();

		if (instances == null) {
			instances = new ArrayList<LightMediaPlayer>();
		}

		instances.add(this);
	}

	@Override
	protected void finalize() {
		super.finalize();
		instances.remove(this);
	}

	public static void resumeAll() {
		if (paused == null) {
			return;
		}

		Iterator<LightMediaPlayer> iter = paused.iterator();
		LightMediaPlayer lmp;

		while (iter.hasNext()) {
			(iter.next()).start();
		}

		paused.clear();
	}

	public static void pauseAll() {
		if (instances == null) {
			return;
		}

		if (paused == null) {
			paused = new ArrayList<LightMediaPlayer>();
		}

		Iterator<LightMediaPlayer> iter = instances.iterator();
		LightMediaPlayer lmp;

		while (iter.hasNext()) {
			lmp = iter.next();

			if (lmp.isPlaying()) {
				paused.add(lmp);
				lmp.pause();
			}
		}
	}
}