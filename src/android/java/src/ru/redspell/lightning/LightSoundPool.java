package ru.redspell.lightning;

public class LightSoundPool extends android.media.SoundPool {
	private static LightSoundPool instance = null;

	public LightSoundPool(int maxStreams, int streamType, int srcQuality) {
		super(maxStreams, streamType, srcQuality);
	}

	public static LightSoundPool getInstance() {
		if (instance == null) {
			instance = new LightSoundPool(100, android.media.AudioManager.STREAM_MUSIC, 0);
		}

		return instance;
	}
}