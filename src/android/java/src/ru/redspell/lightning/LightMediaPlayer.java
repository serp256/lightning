package ru.redspell.lightning;

import android.media.MediaPlayer;
import android.media.AudioManager;
import android.content.res.AssetFileDescriptor;
import android.media.SoundPool;
import ru.redspell.lightning.utils.Log;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.Locale;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.File;

public class LightMediaPlayer extends MediaPlayer {
	private static ArrayList<LightMediaPlayer> instances;
	private static ArrayList<LightMediaPlayer> paused;

	private class CamlCallbackCompleteRunnable implements Runnable {
		private int cb;

		public CamlCallbackCompleteRunnable(int cb) {
			this.cb = cb;
		}

		public native void run();
	}

	private class CamlCallbackCompleteListener implements MediaPlayer.OnCompletionListener {
		private int camlCb;

		public CamlCallbackCompleteListener(int cb) {
			camlCb = cb;
		}

		public void onCompletion(MediaPlayer mp) {
			LightView.instance.queueEvent(new CamlCallbackCompleteRunnable(camlCb));
		}
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

	private static class OffsetSizePair {
		public int offset;
		public int size;

		public OffsetSizePair(int offset, int size) {
			this.offset = offset;
			this.size = size;
		}
	}

	private static native OffsetSizePair getOffsetSizePair(String path);

	private static boolean setMpDataSrc(MediaPlayer mp, String assetsDir, String path) throws IOException {
		Log.d("LIGHTNING", "setMpDataSrc: " + path);

		OffsetSizePair pair = getOffsetSizePair(path);
		File f = assetsDir != null ? new File(assetsDir + (assetsDir.charAt(assetsDir.length() - 1) == '/' ? "" : "/") + path) : null;

		if (pair != null) {
			mp.setDataSource((new FileInputStream(LightView.instance.getExpansionPath(true))).getFD(), pair.offset, pair.size);
			return true;
		} else if (f != null && f.exists()) {
			mp.setDataSource(f.getAbsolutePath());
			return true;
		}

		try {
			AssetFileDescriptor afd = LightView.instance.getContext().getAssets().openFd(path);
			mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());

			return true;
		} catch (IOException e) {
			return false;
		}
	}

	private static int soundPoolLoad(SoundPool sndPool, String path) {
		Log.d("LIGHTNING", "soundPoolLoad: " + path);

		OffsetSizePair pair = getOffsetSizePair(path);
		File f = path.charAt(0) == '/' ? new File(path) : null;

		if (pair != null) {
			try {
				return sndPool.load((new FileInputStream(LightView.instance.getExpansionPath(true))).getFD(), pair.offset, pair.size, 1);	
			} catch (Exception e) {
				return -1;
			}			
		} else if (f != null && f.exists()) {
			return sndPool.load(path, 1);
		}

		try {
			return sndPool.load(LightView.instance.getContext().getAssets().openFd(path), 1);	
		} catch (IOException e) {
			return -1;
		}
	}

	public static MediaPlayer createMediaPlayer(String assetsDir, String path) throws IOException {
		MediaPlayer mp = new LightMediaPlayer();
		String locale = Locale.getDefault().getLanguage();
		mp.setAudioStreamType(AudioManager.STREAM_MUSIC);

		if (!setMpDataSrc(mp, assetsDir, path) && !setMpDataSrc(mp, assetsDir, "locale/" + locale + "/" + path)) {
			if (locale != "en" && !setMpDataSrc(mp, assetsDir, "locale/en/" + path)) {
				return null;
			}
		}

		return mp;
	}

	public static int getSoundId(String path, SoundPool sndPool) throws IOException {
		String locale = Locale.getDefault().getLanguage();
		int retval;

		if ((retval = soundPoolLoad(sndPool, path)) < 0 && (retval = soundPoolLoad(sndPool, "locale/" + locale + "/" + path)) < 0) {
			if (locale != "en") {
				retval = soundPoolLoad(sndPool, "locale/en/" + path);
			}
		}

		return retval;
	}	
}