package ru.redspell.lightning; 

import android.app.Activity;
import android.view.MotionEvent;
import android.opengl.GLSurfaceView;
import android.util.Log;
import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.IOException;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import android.view.Window;
import android.util.DisplayMetrics;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;
import android.content.Intent;
import android.view.SurfaceHolder;
import android.content.Context;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.util.Locale;
import android.net.Uri;
import android.os.Environment;
//import android.os.AsyncTask;
//import android.content.pm.PackageManager.NameNotFoundException;

import ru.redspell.lightning.payments.BillingService;
import ru.redspell.lightning.payments.ResponseHandler;
import com.google.android.vending.expansion.downloader.Helpers;
import com.tapjoy.TapjoyConnect;
import com.tapjoy.TapjoyLog;

import android.os.Process;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.provider.Settings.Secure;
import android.provider.Settings;
import android.view.Display;

import java.nio.ByteBuffer;
import android.graphics.Color;

import ru.redspell.lightning.expansions.XAPKFile;
import java.util.Formatter;

public class LightView extends GLSurfaceView {
    public String getExpansionPath(boolean isMain) {
    	for (XAPKFile xf : activity.getXAPKS()) {
    		if (xf.mIsMain == isMain) {
    			return Helpers.generateSaveFileName(activity, Helpers.getExpansionAPKFileName(activity, xf.mIsMain, xf.mFileVersion));
    		}
    	}

    	return null;
    }

    public int getExpansionVer(boolean isMain) {
    	for (XAPKFile xf : activity.getXAPKS()) {
    		if (xf.mIsMain == isMain) {
    			return xf.mFileVersion;
    		}
    	}

    	return -1;
    }

	private class UnzipCallbackRunnable implements Runnable {
		private String zipPath;
		private String dstPath;
		private boolean success;

		public UnzipCallbackRunnable(String zipPath, String dstPath, boolean success) {
			this.zipPath = zipPath;
			this.dstPath = dstPath;
			this.success = success;
		}

		public native void run();
	}

	private class RmCallbackRunnable implements Runnable {
		private int threadParams;

		public RmCallbackRunnable(int threadParams) {
			this.threadParams = threadParams;
		}

		public native void run();
	}
	
	public String device_id () {
		return Settings.System.getString((getContext ()).getContentResolver(),Secure.ANDROID_ID);
	}

	public boolean isTablet () {
    Display display = activity.getWindowManager().getDefaultDisplay();
    DisplayMetrics displayMetrics = new DisplayMetrics();
    display.getMetrics(displayMetrics);

    int width = displayMetrics.widthPixels / displayMetrics.densityDpi;
    int height = displayMetrics.heightPixels / displayMetrics.densityDpi;

    double screenDiagonal = Math.sqrt( width * width + height * height );
    return (screenDiagonal >= 6.5 );
	}

	public void callUnzipComplete(String zipPath, String dstPath, boolean success) {
		queueEvent(new UnzipCallbackRunnable(zipPath, dstPath, success));
	}

	public void callRmComplete(int cb) {
		queueEvent(new RmCallbackRunnable(cb));
	}

	public String getApkPath() {
		return getContext().getPackageCodePath();
	}

	public String getExternalStoragePath() {
		File storageDir = getContext().getExternalFilesDir(null);
		File assetsDir = new File(storageDir, "assets");

		if (!assetsDir.exists()) {
			assetsDir.mkdir();
		}

		return storageDir.getAbsolutePath() + "/";
	}

	public String getVersion() throws PackageManager.NameNotFoundException {
		Context c = getContext();
		return Integer.toString(c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode);
	}

	private LightRenderer renderer;
	private int loader_id;
	private Handler uithread;
	private BillingService bserv;
	public AndroidFB fb; 

	public static LightView instance;
	
	public LightActivity activity;

	public LightView(LightActivity _activity) {
		super(_activity);
		activity = _activity;

		Log.d("LIGHTNING", "tid: " + Process.myTid());


		activity.requestWindowFeature(Window.FEATURE_NO_TITLE);
		activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
		DisplayMetrics dm = new DisplayMetrics();
		activity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		int width = dm.widthPixels;
		int height = dm.heightPixels;
		lightInit(activity.getPreferences(0));
		Log.d("LIGHTNING","lightInit finished");
		initView(width,height);

		instance = this;

		// FIXME: move it to payments init
		bserv = new BillingService();
		bserv.setContext(activity);
		ResponseHandler.register(activity);

		// FIXME: move it to FB init
		fb = new AndroidFB();
	}

	protected void initView(int width,int height) {
		setEGLContextClientVersion(2);
		Log.d("LIGHTNING","create Renderer");
		renderer = new LightRenderer(width,height);
		setRenderer(renderer);
		setFocusableInTouchMode(true);
	}

	public void surfaceCreated(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceCreated");
		super.surfaceCreated(holder);
	}

	public void surfaceDestroyed(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceDestroyed");
		super.surfaceDestroyed(holder);
	}

	public ResourceParams getResource(String path) {

		ResourceParams res;

		try {
			Log.d("LIGHTNING", "loading from raw assets [" + path + "]");

			AssetFileDescriptor afd = getContext().getAssets().openFd(path);
			res = new ResourceParams(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());			
		} catch (IOException e) {
			Log.d("LIGHTNING","can't find [" + path + "] <" + e + ">");
			res =  null;
		}
		return res;
	}

	public void onPause(){
		Log.d("LIGHTNING", "VIEW.onPause");

		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleOnPause();
			}
		});
		//super.onPause();
	}

	public void onResume() {
		Log.d("LIGHTNING", "VIEW.onResume");
		//super.onResume();

		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleOnResume();
			}
		});
	}

	public void onDestroy() {

		Log.d("LIGHTNING","VIEW.onDestroy");
		//lightFinalize();
		Process.killProcess(Process.myPid());
	}


	public boolean onTouchEvent(final MotionEvent event) {
		//Log.d("LIGHTNING","Touch event");

		dumpMotionEvent(event);

		final int idx;
		final int id;
		final float x;
		final float y;

		switch (event.getActionMasked()) {

			case MotionEvent.ACTION_MOVE:
				final int size = event.getPointerCount();
				final int[] ids = new int[size];
				final float[] xs = new float[size];
				final float[] ys = new float[size];
				final int[] phases = new int[size];
				final boolean hh = event.getHistorySize() > 0 ? true : false;
				for (int i = 0; i < size; i++) {
					ids[i] = event.getPointerId(i);
					xs[i] = event.getX(i);
					ys[i] = event.getY(i);
					if (hh && xs[i] == event.getHistoricalX(i,0) && ys[i] == event.getHistoricalY(i,0)) phases[i] = 2;
					else phases[i] = 1;
				};
				// we need to skip touches without changes of position
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouches(ids, xs, ys,phases);
					}
				});
				break;


			case MotionEvent.ACTION_DOWN:
				// there are only one finger on the screen
				id = event.getPointerId(0);
				x = event.getX(0);
				y = event.getY(0);
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouch(id,x,y,0);
					}
				});
				break;

			case MotionEvent.ACTION_UP:  
				// there are only one finger on the screen
				final int idUp = event.getPointerId(0);
				final float xUp = event.getX(0);
				final float yUp = event.getY(0);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						//renderer.handleActionUp(idUp, xUp, yUp);
						renderer.fireTouch(idUp, xUp, yUp,3);
					}
				});
				break;

			case MotionEvent.ACTION_POINTER_DOWN:
				idx = event.getActionIndex ();
				id = event.getPointerId(idx);
				x = event.getX(idx);
				y = event.getY(idx);
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouch(id,x,y,0);
					}
				});
				break;

			case MotionEvent.ACTION_POINTER_UP:
				idx = event.getActionIndex ();
				id = event.getPointerId(idx);
				x = event.getX(idx);
				y = event.getY(idx);
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouch(id,x,y,3);
					}
				});
				break;

			case MotionEvent.ACTION_CANCEL:
				queueEvent(new Runnable() {
					@Override
					public void run() {
						//renderer.handleActionCancel(ids, xs, ys);
						renderer.cancelAllTouches();
					}
				});
				break;



		}
		return true;
	}

	/*
		 @Override
		 public boolean onKeyDown(int keyCode, KeyEvent event) {
		 final int kc = keyCode;
		 if (keyCode == KeyEvent.KEYCODE_BACK || keyCode == KeyEvent.KEYCODE_MENU) {
		 queueEvent(new Runnable() {
		 @Override
		 public void run() {
		 mRenderer.handleKeyDown(kc);
		 }
		 });
		 return true;
		 }
		 return super.onKeyDown(keyCode, event);
		 }
		 */

	// Show an event in the LogCat view, for debugging
	private static void dumpMotionEvent(MotionEvent event) {
		String names[] = { "DOWN" , "UP" , "MOVE" , "CANCEL" , "OUTSIDE" , "POINTER_DOWN" , "POINTER_UP" , "7?" , "8?" , "9?" };
		StringBuilder sb = new StringBuilder();
		int action = event.getAction();
		int actionCode = action & MotionEvent.ACTION_MASK;
		sb.append("event ACTION_" ).append(names[actionCode]);
		if (actionCode == MotionEvent.ACTION_POINTER_DOWN
				|| actionCode == MotionEvent.ACTION_POINTER_UP) {
			sb.append("(pid " ).append(
						action >> MotionEvent.ACTION_POINTER_INDEX_SHIFT);
			sb.append(")" );
				}
		sb.append("[" );
		for (int i = 0; i < event.getPointerCount(); i++) {
			sb.append("#" ).append(i);
			sb.append("(pid " ).append(event.getPointerId(i));
			sb.append(")=" ).append((int) event.getX(i));
			sb.append("," ).append((int) event.getY(i));
			if (i + 1 < event.getPointerCount())
				sb.append(";" );
		}
		sb.append("]" );
		Log.d("LIGHTNING", sb.toString());
	}


	//
	// Этот методы вызывается из ocaml, он создает хттп-лоадер, который в фоне выполняет запрос с переданными параметрами

	//
	/* а зачем эту хуйню запускать сперва в UI thread? Можно ведь сразу asynch task сделать!
	public int spawnHttpLoader(final String url, final String method, final String[][] headers, final byte[] data) {
		loader_id = loader_id + 1;
		final GLSurfaceView v = this;
		getHandler().post(new Runnable() {
			public void run() {
				UrlReq req = new UrlReq();
				req.url = url;
				req.method = method;
				req.headers = headers;
				req.data = data;
				req.loader_id = loader_id;
				req.surface_view = v;		
				LightHttpLoader loader = new LightHttpLoader();  
				loader.execute(req);
			}
		});

		return loader_id;
	}*/


	private native void lightInit(SharedPreferences p);
	private native void lightFinalize();

	public void requestPurchase(String prodId) {
		bserv.requestPurchase(prodId);
	}

	public void confirmNotif(String notifId) {
		bserv.confirmNotif(notifId);
	}	
	
	public void initBillingServ() {
		bserv.requestPurchase("android.test.purchased");
	}

  public void openURL(String url){
		Context c = getContext();
    Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
		c.startActivity(i);
	}

  private String supportEmail = "mail@redspell.ru";
	public void mlSetSupportEmail(String d){ supportEmail = d; }

  private String additionalExceptionInfo = "\n";
  public void mlAddExceptionInfo(String d) {
		additionalExceptionInfo += d;
		Log.d("LIGHTNING", "additionalExceptionInfo now is" + additionalExceptionInfo + '\n');
		//openURL("mailto:".concat(supportEmail).concat("?subject=test&body=wtf"));
  }

	public void mlUncaughtException(String exn,String[] bt) {
		Context c = getContext();
		ApplicationInfo ai = c.getApplicationInfo ();
		String label = ai.loadLabel(c.getPackageManager ()).toString();
		int vers;
		try { vers = c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode; } catch (PackageManager.NameNotFoundException e) {vers = 1;};
		StringBuffer uri = new StringBuffer("mailto:" + supportEmail);
		Resources res = c.getResources ();
		uri.append("?subject="+ Uri.encode(res.getString(R.string.exception_email_subject) + " \"" + label + "\" v" + vers));
		String t = String.format(res.getString(R.string.exception_email_body),android.os.Build.MODEL,android.os.Build.VERSION.RELEASE,label,vers);
		StringBuffer body = new StringBuffer(t);
		body.append("\n------------------\n");
		body.append(exn);body.append('\n');
		for (String b : bt) {
			body.append(b);body.append('\n');
		};
		body.append(additionalExceptionInfo);
		uri.append("&body=" + Uri.encode(body.toString()));
		Log.d("LIGHTNING","URI: " + uri.toString());
		Intent sendIntent = new Intent(Intent.ACTION_VIEW,Uri.parse(uri.toString ()));
		sendIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		c.startActivity(sendIntent);
	}

  public String mlGetLocale () {
		return Locale.getDefault().getLanguage();
	}

  public String mlGetStoragePath () {
		Log.d("LIGHTNING", "LightView: mlgetStoragePath");
		return getContext().getFilesDir().getPath();
	}

	public void onBackButton() {
		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleBack();
			}
		});
	}


	public void initTapjoy(String appID, String secretKey) {
		//TapjoyLog.enableLogging(true);
		TapjoyConnect.requestTapjoyConnect(getContext().getApplicationContext(),appID,secretKey);
	}

	public void extractExpansions() {
		Log.d("LIGHTNING", "extracting expansions");

	    for (XAPKFile xf : activity.getXAPKS()) {
            String fileName = Helpers.getExpansionAPKFileName(activity, xf.mIsMain, xf.mFileVersion);

            Log.d("LIGHTNING", "checking " + fileName + "...");

            if (!Helpers.doesFileExist(activity, fileName, xf.mFileSize, false)) {
            	Log.d("LIGHTNING", fileName + " does not exists, start download service");

				getHandler().post(new Runnable() {
					@Override
					public void run() {
						activity.startExpansionDownloadService();
					}
				});

            	return;
            }

            Log.d("LIGHTNING", "ok");
        }

        expansionsDownloaded();
	}

	private class ExpansionsExtractedCallbackRunnable implements Runnable {
		native public void run();
	}

	public void expansionsDownloaded() {
		Log.d("LIGHTNING", "expansions downloaded");
		queueEvent(new ExpansionsExtractedCallbackRunnable());
	}

	private static class TexInfo {
		public int width;
		public int height;
		public int legalWidth;
		public int legalHeight;
		public byte[] data;
	}

	public TexInfo decodeImg(byte[] src) {
		Log.d("LIGHTNING", "decodeImg");

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

		if (retval.width != retval.legalWidth || retval.height != retval.legalHeight) {
			Log.d("LIGHTNING", "create new bmp " + String.format("%d %d %d %d", retval.width, retval.height, retval.legalWidth, retval.legalHeight));
			
			try {
				int[] pixels = new int[retval.legalWidth * retval.legalHeight];
				bmp.getPixels(pixels, 0, retval.legalWidth, 0, 0, retval.width, retval.height);

				Bitmap _bmp = Bitmap.createBitmap(retval.legalWidth, retval.legalHeight, Bitmap.Config.ARGB_8888);
				_bmp.setPixels(pixels, 0, retval.legalWidth, 0, 0, retval.legalWidth, retval.legalHeight);
				bmp.recycle();
				bmp = _bmp;
			} catch (Exception e) {
				Log.d("LIGHTNING", "exception " + e.getMessage());
				return null;
			}
		}

		Log.d("LIGHTNING", bmp.toString());

		int bytesPerPixel = 4;

		/*
		Config bmpCfg = bmp.getConfig();

		if (bmpCfg == null) {
			Log.d("LIGHTNING", "unknown config, return null");
		} else {
			switch (bmpCfg) {
				case ARGB_8888:
					Log.d("LIGHTNING", "ARGB_8888");
					break;

				case ALPHA_8:
				case RGB_565:
				case ARGB_4444:
					Log.d("LIGHTNING", "wrong bmp cfg " + bmpCfg);
					return null;
			}
		}*/

		ByteBuffer buf = ByteBuffer.allocate(bmp.getWidth() * bmp.getHeight() * bytesPerPixel);
		bmp.copyPixelsToBuffer(buf);
		bmp.recycle();
		retval.data = buf.array();

		Log.d("LIGHTNING", "return texinfo");

		return retval;
	}

	private static class CurlExternCallbackRunnable implements Runnable {
		private int req;
		private int texInfo;

		public CurlExternCallbackRunnable(int req, int texInfo) {
			this.req = req;
			this.texInfo = texInfo;
		}

		public native void run();
	}

	private static class CurlExternErrorCallbackRunnable implements Runnable {
		private int req;
		private int errCode;
		private int errMes;

		public CurlExternErrorCallbackRunnable(int req, int errCode, int errMes) {
			Log.d("LIGHTNING", "CurlExternErrorCallbackRunnable");

			this.req = req;
			this.errCode = errCode;
			this.errMes = errMes;
		}

		public native void run();
	}

	public void curlExternalLoaderSuccess(int req, int texInfo) {
		queueEvent(new CurlExternCallbackRunnable(req, texInfo));
	}

	public void curlExternalLoaderError(int req, int errCode, int errMes) {
		Log.d("LIGHTNING", "curlExternalLoaderError " + errCode + " " + errMes);
		queueEvent(new CurlExternErrorCallbackRunnable(req, errCode, errMes));
	}

	private static class ExpansionsCallbackRunnable implements Runnable {
		private int cb;

		public ExpansionsCallbackRunnable(int cb) {
			this.cb = cb;
		}

		public native void run();
	}

	public void callExpansionsComplete(int cb) {
		queueEvent(new ExpansionsCallbackRunnable(cb));
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
}
