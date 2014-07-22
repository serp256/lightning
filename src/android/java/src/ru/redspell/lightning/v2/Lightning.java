package ru.redspell.lightning.v2;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.net.Uri;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.view.Display;

import java.io.File;
import java.nio.ByteBuffer;
import java.util.Locale;;

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
    public static native void onBackPressed();

    public static void init() {
    	activity = activity();
        ru.redspell.lightning.utils.OpenUDID.syncContext(activity);
    }

    public static void showUrl(final String url) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                (new UrlDialog(activity, url)).show();
            }
        });
    }

    private static String supportEmail = "mail@redspell.ru";
    private static String additionalExceptionInfo = "\n";

    public static void uncaughtException(String exn,String[] bt) {
        Context c = activity;
        ApplicationInfo ai = c.getApplicationInfo ();
        String label = ai.loadLabel(c.getPackageManager ()).toString() + "(android, " + activity.getString(ru.redspell.lightning.R.string.screen) + ", " + activity.getString(ru.redspell.lightning.R.string.density) + ")";
        int vers;
        try { vers = c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode; } catch (PackageManager.NameNotFoundException e) {vers = 1;};
        StringBuffer uri = new StringBuffer("mailto:" + supportEmail);
        Resources res = c.getResources ();
        uri.append("?subject="+ Uri.encode(res.getString(ru.redspell.lightning.R.string.exception_email_subject) + " \"" + label + "\" v" + vers));
        String t = String.format(res.getString(ru.redspell.lightning.R.string.exception_email_body),android.os.Build.MODEL,android.os.Build.VERSION.RELEASE,label,vers);
        StringBuffer body = new StringBuffer(t);
        body.append("\n------------------\n");
        body.append(exn);body.append('\n');
        for (String b : bt) {
            body.append(b);body.append('\n');
        };      
        body.append(additionalExceptionInfo);
        body.append("\n------------------\n");
        uri.append("&body=" + Uri.encode(body.toString()));
        Log.d("LIGHTNING","URI: " + uri.toString());
        Intent sendIntent = new Intent(Intent.ACTION_VIEW,Uri.parse(uri.toString ()));
        sendIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        c.startActivity(sendIntent);
    }

    public static void setSupportEmail(String mail) {
        supportEmail = mail;
    }

    public static void addExceptionInfo(String d) {
        additionalExceptionInfo += d;
    }

    public static void openURL(String url){
        activity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
    }

    public static String getLocale() {
        return Locale.getDefault().getLanguage();
    }

    public static String getInternalStoragePath () {
        return activity.getFilesDir().getPath();
    }

    public static String getStoragePath() {
        File storageDir = activity.getExternalFilesDir(null);
        if (storageDir != null) return storageDir.getPath();
        return activity.getFilesDir().getPath();
    }

    public static String getVersion() {
        String retval;
        try {
            retval = Integer.toString(activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionCode);
        } catch (PackageManager.NameNotFoundException e) {
            retval = "unknown";
        }

        return retval;
    }

    public static int getScreen() {
        String screen = activity.getString(ru.redspell.lightning.R.string.screen);

        if (screen.contentEquals("small")) return 1;
        if (screen.contentEquals("normal")) return 2;
        if (screen.contentEquals("large")) return 3;
        if (screen.contentEquals("xlarge")) return 4;

        return 0;       
    }    

    public static int getDensity() {
        String density = activity.getString(ru.redspell.lightning.R.string.density);

        if (density.contentEquals("tvdpi")) return 5;
        if (density.contentEquals("ldpi")) return 1;
        if (density.contentEquals("mdpi")) return 2;
        if (density.contentEquals("hdpi")) return 3;
        if (density.contentEquals("xhdpi")) return 4;
        if (density.contentEquals("xxhdpi")) return 6;

        return 0;
    }

    public static boolean isTablet() {
        Display display = activity.getWindowManager().getDefaultDisplay();
        DisplayMetrics displayMetrics = new DisplayMetrics();
        display.getMetrics(displayMetrics);

        float width = displayMetrics.widthPixels / displayMetrics.xdpi;
        float height = displayMetrics.heightPixels / displayMetrics.ydpi;
        double screenDiagonal = Math.sqrt(width * width + height * height);

        return (screenDiagonal >= 6);
    }

    public static String platform() {
        return android.os.Build.VERSION.RELEASE;
    }

    public static String hwmodel() {
        return android.os.Build.MODEL;
    }

    public static long totalMemory() {
        String meminfo;

        try {
            java.io.RandomAccessFile f = new java.io.RandomAccessFile("/proc/meminfo", "r");
            java.util.regex.Pattern regex = java.util.regex.Pattern.compile("^MemTotal:[\\s]*([\\d]+).*$");

            while ((meminfo = f.readLine()) != null) {
                java.util.regex.Matcher matcher = regex.matcher(meminfo);
                
                if (matcher.find()) {
                    meminfo = matcher.group(1);                 
                    break;
                }
            }

            f.close();
        } catch (Exception e) {
            meminfo = null; 
        }

        return meminfo == null ? 0 : (new Long(meminfo)).longValue() * 1024;
    }    

    static {
        System.loadLibrary("test");
    }    
}
