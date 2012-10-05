
package ru.redspell.lightning;

import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import ru.redspell.lightning.utils.Log;
import java.io.InputStream;
import java.io.IOException;



public class LightTexture {
	public static void loadImage(InputStream is) {
		try {
			Log.d("TEXTURE","Avail bytes: " + is.available());
		} catch (IOException s) {
			throw new RuntimeException("Unable to get available...");
		}
		Bitmap bmp = BitmapFactory.decodeStream(is);
		if (bmp == null) {
			Log.d("TEXTURE","bitmap readed: " + bmp.getHeight() + ":" + bmp.getWidth());
		} else Log.d("TEXTURE","bitmap is null");
	}
}
