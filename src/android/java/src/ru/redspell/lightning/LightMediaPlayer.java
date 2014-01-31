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
	public int id;
	private static int nextId = 0;

	public static class LifecycleHelper implements IUiLifecycleHelper {
		public void onCreate(android.os.Bundle savedInstanceState) {}
		public native void onResume();
		public native void onPause();
		public void onActivityResult(int requestCode, int resultCode, android.content.Intent data) {}
		public void onSaveInstanceState(android.os.Bundle outState) {}
		public void onStop() {}
		public void onDestroy() {}
	};

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
		Log.d("LMP", "start " + id);

		//seekTo(getDuration() - 10000);
		setOnCompletionListener(new CamlCallbackCompleteListener(cb));
		setOnErrorListener(new OnErrorListener() {
			public boolean onError(MediaPlayer mp, int what, int extra) {
				Log.d("LMP", "mp error " + ((LightMediaPlayer)mp).id);

				return true;
			}
		});

		start();
	}

	public LightMediaPlayer() {
		super();

		if (instances == null) {
			instances = new ArrayList<LightMediaPlayer>();
		}

		id = nextId++;

		Log.d("LMP", "new instance " + id);

		instances.add(this);
	}

	@Override
	public void stop() {
		Log.d("LMP", "stop " + id);
		super.stop();
	}

	@Override
	protected void finalize() {
		Log.d("LMP", "finalize");

		super.finalize();
		instances.remove(this);
	}

	public static void resumeAll() {
		Log.d("LMP", "-----resumeAll");

		if (paused == null) {
			return;
		}

		Iterator<LightMediaPlayer> iter = paused.iterator();
		LightMediaPlayer lmp;

		while (iter.hasNext()) {
			lmp = iter.next();

			Log.d("LMP", "resume mp " + lmp.id);
			lmp.start();
		}

		paused.clear();
		Log.d("LMP", "resumeAll-----");
	}

	public static void pauseAll() {
		Log.d("LMP", "-----pauseAll");

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

			Log.d("LMP", "pause mp " + lmp.id);

			try {
				if (lmp.isPlaying()) {
					Log.d("LMP", "mp " + lmp.id + " is playing");

					paused.add(lmp);
					lmp.pause();
				}				
			} catch (IllegalStateException e) {}
		}

		Log.d("LMP", "pauseAll-----");
	}

	private static class OffsetSizePair {
		public int offset;
		public int size;
		public int location;

		public OffsetSizePair(int offset, int size, int location) {
			this.offset = offset;
			this.size = size;
			this.location = location;
		}
	}

	private static native OffsetSizePair getOffsetSizePair(String path);

	private static String getFpathByLocation(int location) {
		if (location == 0) {
			return LightView.instance.getApkPath();
		}

		return LightView.instance.getExpansionPath(location == 2);
	}

	private static boolean setMpDataSrc(MediaPlayer mp, String path) throws IOException {
		Log.d("LIGHTNING", "setMpDataSrc: " + path);

		OffsetSizePair pair = getOffsetSizePair(path);

		if (pair == null) return false;

		String fpath = getFpathByLocation(pair.location);
		if (fpath == null) return false;

		mp.setDataSource(new FileInputStream(fpath).getFD(), pair.offset, pair.size);
		return true;
	}

	private static int soundPoolLoad(SoundPool sndPool, String path) {
		Log.d("LIGHTNING", "soundPoolLoad: " + path);

		OffsetSizePair pair = getOffsetSizePair(path);

		if (pair == null) return -1;

		String fpath = getFpathByLocation(pair.location);
		if (fpath == null) return -1;

		try {
			return sndPool.load(new FileInputStream(fpath).getFD(), pair.offset, pair.size, 1);	
		} catch (Exception e) {
			return -1;
		}
	}

	public static MediaPlayer createMediaPlayer(String path) throws IOException {
		MediaPlayer mp = new LightMediaPlayer();
		// String locale = Locale.getDefault().getLanguage();
		mp.setAudioStreamType(AudioManager.STREAM_MUSIC);
		return setMpDataSrc(mp, path) ? mp : null;

/*		if (!setMpDataSrc(mp, path) && !setMpDataSrc(mp, "locale/" + locale + "/" + path)) {
			if (locale != "en" && !setMpDataSrc(mp, "locale/en/" + path)) {
				return null;
			}
		}

		return mp;*/
	}

	public static int getSoundId(String path, SoundPool sndPool) throws IOException {
		// String locale = Locale.getDefault().getLanguage();
		// int retval = soundPoolLoad(sndPool, path);

/*		if ((retval = soundPoolLoad(sndPool, path)) < 0 && (retval = soundPoolLoad(sndPool, "locale/" + locale + "/" + path)) < 0) {
			if (locale != "en") {
				retval = soundPoolLoad(sndPool, "locale/en/" + path);
			}
		}*/

		return soundPoolLoad(sndPool, path);
	}
}