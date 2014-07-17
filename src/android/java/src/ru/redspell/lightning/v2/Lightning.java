package ru.redspell.lightning.v2;

import android.content.Context;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.os.Vibrator;

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

    public static void vibrate(final int time) {
        activity.runOnUiThread(new Runnable(){
            @Override
            public void run(){
                Log.d("LIGHTNING", "vibrate " + time);
                Vibrator v = (Vibrator)activity.getSystemService(Context.VIBRATOR_SERVICE);
                v.vibrate(time);
            }
        });
    }

    public static String getOldUDID() {
        return ru.redspell.lightning.utils.UDID.get();
    }    

    public static String getUDID() {
        return ru.redspell.lightning.utils.OpenUDID.getOpenUDIDInContext();
    }

    public static native NativeActivity activity();
    public static native void disableTouches();
    public static native void enableTouches();
    public static native void convertIntent(Intent intent);

    public static void init() {
    	activity = activity();
        ru.redspell.lightning.utils.OpenUDID.syncContext(activity.getApplicationContext());
    }

    public static void showUrl(final String url) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                (new UrlDialog(activity, url)).show();
            }
        });
    }

    static {
        System.loadLibrary("test");
    }    
}
