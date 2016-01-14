package ru.redspell.lightning;

import android.app.ProgressDialog;
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
import android.os.Build;
import android.util.DisplayMetrics;
import android.view.Display;

import java.io.File;
import java.nio.ByteBuffer;
import java.util.Locale;
import java.util.ArrayList;
import java.util.Iterator;
import org.json.JSONObject;
import org.json.JSONException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.channels.FileChannel;
import org.apache.http.client.HttpClient;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.HttpResponse;
import org.apache.http.entity.ByteArrayEntity;

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

		Log.d("LIGHTNING", "1");
		TexInfo retval = new TexInfo();

		Log.d("LIGHTNING", "2");
		retval.width = bmp.getWidth();
		retval.height = bmp.getHeight();
		retval.legalWidth = Math.max(64, retval.width);
		retval.legalHeight = Math.max(64, retval.height);

		Bitmap.Config conf = bmp.getConfig();

		if (conf == null) {
			Log.d("LIGHTNING", "null config");
			return null;
		}

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

			default:
				Log.d("LIGHTNING", "unknown bitmap config");
				return null;
		}

		Log.d("LIGHTNING", "retval.format " + (retval.format == null ? "null" : retval.format));

		Log.d("LIGHTNING", "4");
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
		Log.d("LIGHTNING", "5");

		ByteBuffer buf = ByteBuffer.allocate(bmp.getRowBytes() * bmp.getHeight());
		bmp.copyPixelsToBuffer(buf);
		bmp.recycle();
		retval.data = buf.array().clone();
		Log.d("LIGHTNING", "6");

		Log.d("LIGHTNING", "return texinfo");

		return retval;
	}

	public static void setBackgroundCallbackDelay(long delay) {
		NativeActivity.instance.setBackgroundCallbackDelay(delay);
	}

	public static void resetBackgroundCallbackDelay() {
		NativeActivity.instance.resetBackgroundCallbackDelay();
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

    public static native void disableTouches();
    public static native void enableTouches();
    public static native void convertIntent(Intent intent);
    public static native void onBackPressed();

    public static void init() {
    	activity = NativeActivity.instance;
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
			String screen = activity.getString(ru.redspell.lightning.R.string.screen);
			return (screen.contentEquals("large") || screen.contentEquals("xlarge"));

/*				if (Build.MODEL.contentEquals("HTC One X")) {
					return false;
				}

        Display display = activity.getWindowManager().getDefaultDisplay();
        DisplayMetrics displayMetrics = new DisplayMetrics();
        display.getMetrics(displayMetrics);
*/
/*			Log.d("LIGHTNING", "Build.MANUFACTURER " + Build.MANUFACTURER);
				Log.d("LIGHTNING", "Build.MODEL " + Build.MODEL);
				Log.d("LIGHTNING", "displayMetrics.widthPixels " + displayMetrics.widthPixels);
				Log.d("LIGHTNING", "displayMetrics.heightPixels " + displayMetrics.heightPixels);
				Log.d("LIGHTNING", "displayMetrics.xdpi " + displayMetrics.xdpi);
				Log.d("LIGHTNING", "displayMetrics.ydpi " + displayMetrics.ydpi);*/

/*        float width = displayMetrics.widthPixels / displayMetrics.xdpi;
        float height = displayMetrics.heightPixels / displayMetrics.ydpi;
*/
/*				Log.d("LIGHTNING", "width " + width);
				Log.d("LIGHTNING", "height " + height);*/
/*        double screenDiagonal = Math.sqrt(width * width + height * height);*/
/*				Log.d("LIGHTNING", "screenDiagonal " + screenDiagonal);*/

/*        return (screenDiagonal >= 6);*/
    }

    public static String platform() {
        return android.os.Build.VERSION.RELEASE;
    }

    public static String hwmodel() {
        return android.os.Build.MODEL;
    }

		
		private static String getSystemFontName (String locale) {
			int version = android.os.Build.VERSION.SDK_INT;
			Log.d ("LIGHTNING", "locale " + locale + " version "  + version );
			if (locale.equals("zh")) {
				if (version >= 21) {
					//return "NotoSansSC-Regular.otf";
					return "NotoNaskhArabic-Regular.ttf";
				}
				else {
					return "DroidSansFallback.ttf";
				}
			}
			else {
				if (version >=14) {
					return "Roboto-Regular.ttf";
				}
				else {
					return "DroidSans.ttf";
				}
			}
		}
		
		
		public static String getSystemFontPath (String lcl) {
			Log.d ("LIGHTNING","getSystemFontPath " + lcl);
			String[] fontdirs = { "/system/fonts", "/system/font", "/data/fonts" };
 
			Log.d ("LIGHTNING","getSystemFontName" + lcl);
				String fontName = getSystemFontName(lcl);

        for ( String fontdir : fontdirs ) {
            File dir = new File( fontdir );
 
            if (!dir.exists())
                continue;
 
            File[] files = dir.listFiles();
 
            if (files == null)
                continue;
 
            for ( File file : files ) {
							if (file.getName().equals(fontName)) {
								Log.d ("LIGHTNING","font:" + file.getName());
								return (file.getAbsolutePath ());
							}
            }
        }
				return "";
		}

    private static ProgressDialog progressDialog;

    public static void showNativeWait(final String message) {
        if (progressDialog != null) progressDialog.dismiss();

        activity.runOnUiThread(
            new Runnable() {
                @Override
                public void run() {
                    progressDialog = new ProgressDialog(activity);
                    progressDialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
                    progressDialog.setIndeterminate(true);
                    progressDialog.setCancelable(false);
                    if (message != null) progressDialog.setMessage(message);
                    progressDialog.show();
                }
            }
        );
    }

    public static void hideNativeWait() {
        if (progressDialog != null) progressDialog.dismiss();
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

		public static String appVer() {
			int ver;
			try {
				ver = Lightning.activity.getPackageManager().getPackageInfo(Lightning.activity.getPackageName(), 0).versionCode;
			} catch(PackageManager.NameNotFoundException e) {
				ver = 1;
			};

			return (new Integer(ver)).toString();
		}

		public static boolean silentExceptions = true;

/*		public static void uncaughtException(String exn,String[] bt) {
			Log.d("LIGHTNING", "silentExceptions " + silentExceptions);

			if (silentExceptions) {
				uncaughtExceptionSilent(exn, bt);
			} else {
				uncaughtExceptionByMail(exn, bt);
			}
		}
*/
		private static void flushErrLog() {
			Log.d("LIGHTNING", "flushErrLog");

			try {
				FileInputStream errLogStream = Lightning.activity.openFileInput("error_log");
				FileChannel errLogChan = errLogStream.getChannel();
				ByteBuffer buf = ByteBuffer.allocate((int)errLogChan.size()); // hope error_log never reaches size more than int capacity
				errLogChan.read(buf);

				HttpClient client = new DefaultHttpClient();
				HttpPost req = new HttpPost("http://mobile-errors.redspell.ru/submit?app_name=" + Lightning.activity.getPackageName());
				Log.d("LIGHTNING", "request " + req.getURI());
				req.setEntity(new ByteArrayEntity(buf.array()));
				HttpResponse resp = client.execute(req);

				Log.d("LIGHTNING", "RESP CODE " + resp.getStatusLine().getStatusCode());
				if (resp.getStatusLine().getStatusCode() == 200) {
					Lightning.activity.deleteFile("error_log");
				}
			} catch (Exception e) {
				Log.d("LIGHTNING", "java exception when flushing error_log");
				e.printStackTrace();
			}
		}

/*		public static void uncaughtExceptionSilent(String exn, String[] bt) {
			long now = System.currentTimeMillis() / 1000L;
			String dev = android.os.Build.MODEL;
			int ver;
			try {
				ver = Lightning.activity.getPackageManager().getPackageInfo(Lightning.activity.getPackageName(), 0).versionCode;
			} catch(PackageManager.NameNotFoundException e) {
				ver = 1;
			};
			StringBuffer backtraceBuf = new StringBuffer();
			StringBuffer expnInfBuf = new StringBuffer();
			Iterator<String> iter = additionalExceptionInfo.iterator();
			while (iter.hasNext()) {
				expnInfBuf.append("\t");
				expnInfBuf.append(iter.next());
				expnInfBuf.append("\n");
			}

			if (bt.length > 0) {
				if (bt[0] != null) exn += "\n" + bt[0];
				for (int i = 1; i < bt.length; i++) {
					if (bt[i] != null) {
						backtraceBuf.append("\n");
						backtraceBuf.append(bt[i]);
					}
				}
			}

			if (expnInfBuf.length() > 0) {
				backtraceBuf.append("exception info:");
				backtraceBuf.append(expnInfBuf);
			}

			JSONObject json = new JSONObject();
			try {
				json.put("date", now);
				json.put("device", dev);
				json.put("vers", (new Integer(ver)).toString());
				json.put("exception", exn);
				json.put("data", backtraceBuf.toString());
			} catch (JSONException e) {
				Log.d("LIGHTNING", "wtf?" + e.toString());
			}

			try {
				FileOutputStream errLogStream = Lightning.activity.openFileOutput("error_log", Context.MODE_APPEND);
				byte[] bytes = json.toString().getBytes();
				errLogStream.write(bytes, 0, bytes.length);
				flushErrLog();
			} catch (Exception e) {

			}
		}*/
		public static void silentUncaughtException(String exceptionJson) {
			Log.d("LIGHTNING", "silentUncaughtException call " + exceptionJson);
			try {
				FileOutputStream errLogStream = Lightning.activity.openFileOutput("error_log", Context.MODE_APPEND);
				byte[] bytes = exceptionJson.getBytes();
				errLogStream.write(bytes, 0, bytes.length);
				flushErrLog();
			} catch (Exception e) {
				Log.d("LIGHTNING", "java exception when writing ocaml exception data in error_log");
				e.printStackTrace();
			}
		}

		public static String[] uncaughtExceptionByMailSubjectAndBody() {
			Context c = activity;
			ApplicationInfo ai = c.getApplicationInfo ();
			String label = ai.loadLabel(c.getPackageManager ()).toString() + "(android, " + activity.getString(ru.redspell.lightning.R.string.screen) + ", " + activity.getString(ru.redspell.lightning.R.string.density) + ")";
			int vers;
			try { vers = c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode; } catch (PackageManager.NameNotFoundException e) {vers = 1;};

			Resources res = c.getResources ();
			String[] retval = {
				res.getString(ru.redspell.lightning.R.string.exception_email_subject) + " \"" + label + "\" v" + vers,
				String.format(res.getString(ru.redspell.lightning.R.string.exception_email_body),android.os.Build.MODEL,android.os.Build.VERSION.RELEASE,label,vers)
			};

			return retval;
		}

		public static void disableLog () {
			ru.redspell.lightning.utils.Log.enabled = false;
		}

/*		public static void uncaughtExceptionByMail(String exn, String[] bt) {
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

				StringBuffer expnInfBuf = new StringBuffer();
				Iterator<String> iter = additionalExceptionInfo.iterator();
				while (iter.hasNext()) {
					expnInfBuf.append(iter.next());
					expnInfBuf.append("\n");
				}
				body.append(expnInfBuf);

				body.append("\n------------------\n");
				uri.append("&body=" + Uri.encode(body.toString()));
				Log.d("LIGHTNING","URI: " + uri.toString());
				Intent sendIntent = new Intent(Intent.ACTION_VIEW,Uri.parse(uri.toString ()));
				sendIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
				c.startActivity(sendIntent);
		}*/

    static {
        try {
            NativeActivity activity = NativeActivity.instance;

            Log.d("LIGHTNING", "--------------------------------");

            for (android.content.pm.ActivityInfo activityInfo : activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_ACTIVITIES | PackageManager.GET_META_DATA).activities) {
                Log.d("LIGHTNING", "!!!! activity " + activityInfo.name);

                if (activityInfo.name.contentEquals("ru.redspell.lightning.NativeActivity")) {
                    android.os.Bundle meta = activityInfo.metaData;
                    Log.d("LIGHTNING", "meta size " + meta.size());
                    java.util.Iterator<String> iter = meta.keySet().iterator();
                    while (iter.hasNext()) {
                        Log.d("LIGHTNING", "key " + iter.next());
                    }

                    Log.d("LIGHTNING", "meta.getString " + meta.getString("android.app.lib_name"));
                    System.loadLibrary(meta.getString("android.app.lib_name"));
                }
            }

            Log.d("LIGHTNING", "--------------------------------");
        } catch (Exception e) {
			Log.d("LIGHTNING", "-------------------EXCEPTION-------------------");
			e.printStackTrace();
        }
    }
}
