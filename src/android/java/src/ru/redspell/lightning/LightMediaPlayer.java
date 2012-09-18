package ru.redspell.lightning;

import android.media.MediaPlayer;
import android.media.AudioManager;
import android.content.res.AssetFileDescriptor;
import android.media.SoundPool;
import android.util.Log;

import java.util.ArrayList;
import java.util.Iterator;
import java.io.IOException;
import java.io.FileInputStream;

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

	private static boolean setMpDataSrc(MediaPlayer mp, String path) {
		OffsetSizePair pair = getOffsetSizePair(path);

		if (pair != null) {
			mp.setDataSource((new FileInputStream(LightView.instance.getExpansionPath(true))).getFD(), pair.offset, pair.size);
			return true;
		} else if (assetsDir != null) {
			mp.setDataSource(assetsDir + (assetsDir.charAt(assetsDir.length() - 1) == '/' ? "" : "/") + path);
		} else {
			AssetFileDescriptor afd = LightView.instance.getContext().getAssets().openFd(path);
			mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());	
		}

		return false;		
	}

	public static MediaPlayer createMediaPlayer(String assetsDir, String path) throws IOException {
		MediaPlayer mp = new LightMediaPlayer();
		mp.setAudioStreamType(AudioManager.STREAM_MUSIC);

		OffsetSizePair pair = getOffsetSizePair(path);

		if (pair != null) {
			mp.setDataSource((new FileInputStream(LightView.instance.getExpansionPath(true))).getFD(), pair.offset, pair.size);
		} else if (assetsDir != null) {
			mp.setDataSource(assetsDir + (assetsDir.charAt(assetsDir.length() - 1) == '/' ? "" : "/") + path);
		} else {
			AssetFileDescriptor afd = LightView.instance.getContext().getAssets().openFd(path);
			mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());	
		}

		return mp;
	}

	public static int getSoundId(String path, SoundPool sndPool) throws IOException {
		OffsetSizePair pair = getOffsetSizePair(path);

		if (pair != null) {
			sndPool.load((new FileInputStream(LightView.instance.getExpansionPath(true))).getFD(), pair.offset, pair.size, 1);
		} else if (path.charAt(0) == '/') {
			return sndPool.load(path, 1);
		}

		return sndPool.load(LightView.instance.getContext().getAssets().openFd(path), 1);
	}	
}