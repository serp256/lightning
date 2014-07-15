package ru.redspell.lightning.v2;

import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;

import java.nio.ByteBuffer;

import ru.redspell.lightning.utils.Log;

public class Lightning {
	public static NativeActivity activity = null;

    private static class TexInfo {
        public int width;
        public int height;
        public int legalWidth;
        public int legalHeight;
        public byte[] data;
        public String format;
    }

    public static TexInfo decodeImg(byte[] src) {
        Log.d("LIGHTNING", "decodeImg " + src.length);

        Bitmap bmp = BitmapFactory.decodeByteArray(src, 0, src.length);

        if (bmp == null) {
            Log.d("LIGHTNING", "cannot create bitmap");
            return null;
        }

        TexInfo retval = new TexInfo();

        retval.width = bmp.getWidth();
        retval.height = bmp.getHeight();
        retval.legalWidth = Math.max(64, retval.width);
        retval.legalHeight = Math.max(64, retval.height);

        switch (bmp.getConfig()) {
            case ALPHA_8:
                retval.format = "ALPHA_8";
                break;

            case ARGB_4444:
                retval.format = "ARGB_4444";
                break;

            case ARGB_8888:
                retval.format = "ARGB_8888";
                break;

            case RGB_565:
                retval.format = "RGB_565";
                break;
        }

        // retval.format = "ARGB_8888";

        Log.d("LIGHTNING", "retval.format " + retval.format);

        if (retval.width != retval.legalWidth || retval.height != retval.legalHeight) {
            try {
                int[] pixels = new int[retval.legalWidth * retval.legalHeight];
                bmp.getPixels(pixels, 0, retval.legalWidth, 0, 0, retval.width, retval.height);

                Bitmap _bmp = Bitmap.createBitmap(retval.legalWidth, retval.legalHeight, bmp.getConfig());
                _bmp.setPixels(pixels, 0, retval.legalWidth, 0, 0, retval.legalWidth, retval.legalHeight);
                bmp.recycle();
                bmp = _bmp;
            } catch (Exception e) {
                Log.d("LIGHTNING", "exception " + e.getMessage());
                return null;
            }
        }

        ByteBuffer buf = ByteBuffer.allocate(bmp.getRowBytes() * bmp.getHeight());
        bmp.copyPixelsToBuffer(buf);
        bmp.recycle();
        retval.data = buf.array();

        Log.d("LIGHTNING", "return texinfo");

        return retval;
    }

    public static String locale() {
    	ru.redspell.lightning.utils.Log.d("LIGHTNING", "locale");
        return java.util.Locale.getDefault().getLanguage();
    }

    public static native NativeActivity activity();

    public static void init() {
    	activity = activity();
    }

    static {
        System.loadLibrary("test");
    }    
}