package ru.redspell.lightning; 

import java.util.ArrayList;
import java.util.Iterator;
import android.app.Activity;
import android.view.MotionEvent;
import android.opengl.GLSurfaceView;
import ru.redspell.lightning.utils.Log;
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
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.util.Locale;
import android.net.Uri;
import android.os.Environment;
import android.content.res.Configuration;
import android.app.ProgressDialog;

//import ru.redspell.lightning.payments.BillingService;
//import ru.redspell.lightning.payments.ResponseHandler;
import com.google.android.vending.expansion.downloader.Helpers;

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
import java.util.HashMap;

import android.net.wifi.WifiManager;
import android.net.wifi.WifiInfo;
//import ru.redspell.lightning.LightEGLContextFactory;

import ru.redspell.lightning.payments.google.LightGooglePayments;
import ru.redspell.lightning.payments.amazon.LightAmazonPayments;
import ru.redspell.lightning.payments.ILightPayments;
import java.util.UUID;

import android.os.Build;
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import android.app.ActivityManager;
import android.app.ActivityManager.MemoryInfo;

public class LightView extends GLSurfaceView {
    public String getExpansionPath(boolean isMain) {
    	for (XAPKFile xf : activity.getExpansions()) {
    		if (xf.mIsMain == isMain) {
    			return Helpers.generateSaveFileName(activity, Helpers.getExpansionAPKFileName(activity, xf.mIsMain, xf.mFileVersion));
    		}
    	}

    	return null;
    }

    public int getExpansionVer(boolean isMain) {
    	for (XAPKFile xf : activity.getExpansions()) {
    		if (xf.mIsMain == isMain) {
    			return xf.mFileVersion;
    		}
    	}

    	return -1;
    }

    private class CamlFailwithRunnable implements Runnable {
    	private String errMes;

    	public CamlFailwithRunnable(String errMes) {
    		this.errMes = errMes;
    	}

    	public native void run();
    }

    public void camlFailwith(String errMes) {
    	instance.queueEvent(new CamlFailwithRunnable(errMes));
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

	/*
	public String device_id () {
		return Settings.System.getString((getContext ()).getContentResolver(),Secure.ANDROID_ID);
	}

	public String get_mac_id () {
		Log.d ("LIGHTNING", "get_mac_id call");

		WifiManager manager = (WifiManager)  (getContext ()).getSystemService(Context.WIFI_SERVICE);
		String macAddress = "";
		if (manager != null) {
			Log.d ("LIGHTNING", "wifi manager not null");
			WifiInfo info = manager.getConnectionInfo();
			if (info != null) { 
				Log.d ("LIGHTNING", "wifi info not null");
				macAddress = info.getMacAddress();
				if (macAddress == null) {
					macAddress = "";
				}
			}
		}
		return macAddress.toUpperCase ();
	}
*/

	public boolean isTablet () {
			
			Log.d("LIGHTNING", "widthPixels " + displayMetrics.widthPixels + " xhdpi " + displayMetrics.xdpi );
	    float width = displayMetrics.widthPixels / displayMetrics.xdpi;
			Log.d("LIGHTNING", "width" + width);
			Log.d("LIGHTNING", "heightPixels " + displayMetrics.heightPixels + " yhdpi " + displayMetrics.ydpi );
	    float height = displayMetrics.heightPixels / displayMetrics.ydpi;
			Log.d("LIGHTNING", "height : " + height);

	    double screenDiagonal = Math.sqrt(width * width + height * height);
			Log.d("LIGHTNING", "diagonal=" + screenDiagonal);
	    return (screenDiagonal >= 6);
	}

	// public int getScreenWidth() {
	// 	return displayMetrics.widthPixels;
	// }

	// public int getScreenHeight() {
	// 	return displayMetrics.heightPixels;
	// }

	public int getScreen() {
		/*
		Configuration conf = getResources().getConfiguration();

		switch (conf.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK) {
			case Configuration.SCREENLAYOUT_SIZE_SMALL:
				return 0;

			case Configuration.SCREENLAYOUT_SIZE_NORMAL:
				return 1;

			case Configuration.SCREENLAYOUT_SIZE_LARGE:
				return 2;

			case Configuration.SCREENLAYOUT_SIZE_UNDEFINED:
				return -1;

			default:
				return 3;
		}*/
		String screen = activity.getString(R.string.screen);
		Log.d("LIGHTNING", "java screen " + screen);

		if (screen.contentEquals("small")) return 1;
		if (screen.contentEquals("normal")) return 2;
		if (screen.contentEquals("large")) return 3;
		if (screen.contentEquals("xlarge")) return 4;

		return 0;		
	}

	public int getDensity() {
		String density = activity.getString(R.string.density);
		Log.d("LIGHTNING", "java density " + density);

		if (density.contentEquals("tvdpi")) return 5;
		if (density.contentEquals("ldpi")) return 1;
		if (density.contentEquals("mdpi")) return 2;
		if (density.contentEquals("hdpi")) return 3;
		if (density.contentEquals("xhdpi")) return 4;
		if (density.contentEquals("xxhdpi")) return 6;

		return 0;
	}

	public void callUnzipComplete(String zipPath, String dstPath, boolean success) {
		queueEvent(new UnzipCallbackRunnable(zipPath, dstPath, success));
	}

	public void callRmComplete(int cb) {
		queueEvent(new RmCallbackRunnable(cb));
	}

	public String getApkPath() {
		Log.d("LIGHTNING","getApkPath");
		return getContext().getPackageCodePath();
	}

	/*
	public String getAssetsPath() {
		Log.d("LIGHTNING", "getAssetsPath");
		File storageDir = getContext().getExternalFilesDir(null);
		File assetsDir = new File(storageDir, "assets");

		if (!assetsDir.exists()) {
			assetsDir.mkdir();
		}

		return storageDir.getAbsolutePath() + "/";
	}*/

	public String getVersion() throws PackageManager.NameNotFoundException {
		Context c = getContext();
		return Integer.toString(c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionCode);
	}

	private LightRenderer renderer;
	private int loader_id;
	private Handler uithread;
	// private BillingService bserv;

	public static LightView instance;
	
	public LightActivity activity;
	private DisplayMetrics displayMetrics;

	protected static final String PREFS_FILE = "device_id.xml";
	protected static final String PREFS_DEVICE_ID = "device_id";

	protected volatile static String uuid;


	public static final String md5(final String s) {
			try {
					// Create MD5 Hash
					MessageDigest digest = java.security.MessageDigest
									.getInstance("MD5");
					digest.update(s.getBytes());
					byte messageDigest[] = digest.digest();

					// Create Hex String
					StringBuffer hexString = new StringBuffer();
					for (int i = 0; i < messageDigest.length; i++) {
							String h = Integer.toHexString(0xFF & messageDigest[i]);
							while (h.length() < 2)
									h = "0" + h;
							hexString.append(h);
					}
					return hexString.toString();

			} catch (NoSuchAlgorithmException e) {
					e.printStackTrace();
			}
			return "00000000000000000000000000000000";
	}



	public LightView(LightActivity _activity) {
		super(_activity);
		activity = _activity;

		Display display = activity.getWindowManager().getDefaultDisplay();
		displayMetrics = new DisplayMetrics();
		display.getMetrics(displayMetrics);

		Log.d("LIGHTNING", "tid: " + Process.myTid());

		if (uuid == null) {
				Log.d("LIGHTNING", "id is null");
//				String serial = android.os.Build.HARDWARE; 
				String serial = md5 (
				Build.BOARD + Build.BRAND
				+ Build.CPU_ABI + Build.DEVICE
				+ Build.DISPLAY + Build.HOST
				+ Build.ID + Build.MANUFACTURER
				+ Build.MODEL + Build.PRODUCT
				+ Build.TAGS + Build.TYPE
				+ Build.USER);
		
				Log.d ("LIGHTNING", "Board: " + Build.BOARD);
				Log.d ("LIGHTNING", "Brand: " + Build.BRAND);
				Log.d ("LIGHTNING", "CPU_ABI: " + Build.CPU_ABI);
				Log.d ("LIGHTNING", "DISPLAY: " + Build.DISPLAY);
				Log.d ("LIGHTNING", "ID: " + Build.ID);
				Log.d ("LIGHTNING", "DEVICE: " + Build.DEVICE);
				Log.d ("LIGHTNING", "HOST: " + Build.HOST);
				Log.d ("LIGHTNING", "MANUFACTURER: " + Build.MANUFACTURER);
				Log.d ("LIGHTNING", "MODEL: " + Build.MODEL);
				Log.d ("LIGHTNING", "TAGS: " + Build.TAGS);
				Log.d ("LIGHTNING", "PRODUCT: " + Build.PRODUCT);
				Log.d ("LIGHTNING", "TYPE: " + Build.TYPE);
				Log.d ("LIGHTNING", "USER: " + Build.USER);

				Log.d("LIGHTNING", "serial: " + serial);
				final String android_id = Settings.System.getString((getContext ()).getContentResolver(),Secure.ANDROID_ID);
				if (!"9774d56d682e549c".equals(android_id) && !"0000000000000000".equals(android_id)  ) {
					uuid =android_id;
				} else {
					Log.d("LIGHTNING", "get preferences" );
					final SharedPreferences prefs = (getContext ()).getSharedPreferences( PREFS_FILE, 0);
					Log.d("LIGHTNING", "get deviec id" );
					final String id = prefs.getString(PREFS_DEVICE_ID, null );
					if (id == null) {
						uuid = (UUID.randomUUID ()).toString ();
						prefs.edit().putString(PREFS_DEVICE_ID, uuid).commit();
					} else {
						Log.d("LIGHTNING", "id is not null");
						uuid = id;
					}
				};
			uuid = uuid + "_" + serial;
			Log.d("LIGHTNING", "uuid: " + uuid);
		};

		activity.requestWindowFeature(Window.FEATURE_NO_TITLE);
		activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
		activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
		DisplayMetrics dm = new DisplayMetrics();
		activity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		int width = dm.widthPixels;
		int height = dm.heightPixels;

		AssetManager am = activity.getAssets();

		AssetFileDescriptor indexFd = null;
		AssetFileDescriptor assetsFd = null;

		try {
			indexFd = am.openFd("index");
			assetsFd = am.openFd("assets");

			ru.redspell.lightning.expansions.XAPKFile[] expansions = activity.getExpansions();
			String mainExpPath = null;
			String patchExpPath = null;

			if (expansions.length > 2) {
				mlUncaughtException("something wrong: more than 2 expansion files", new String[]{});
			} else if (expansions.length == 2) {
				if (expansions[0].mIsMain) {
					mainExpPath = Helpers.getExpansionAPKFileName(activity, expansions[0].mIsMain, expansions[0].mFileVersion);
					patchExpPath = Helpers.getExpansionAPKFileName(activity, expansions[1].mIsMain, expansions[1].mFileVersion);
				} else {
					patchExpPath = Helpers.getExpansionAPKFileName(activity, expansions[0].mIsMain, expansions[0].mFileVersion);
					mainExpPath = Helpers.getExpansionAPKFileName(activity, expansions[1].mIsMain, expansions[1].mFileVersion);				
				}
			} else if (expansions.length == 1) {
				mainExpPath = Helpers.getExpansionAPKFileName(activity, expansions[0].mIsMain, expansions[0].mFileVersion);
			}

			if (mainExpPath != null) mainExpPath = Helpers.generateSaveFileName(activity, mainExpPath);
			if (patchExpPath != null) patchExpPath = Helpers.generateSaveFileName(activity, patchExpPath);

			String err = lightInit(activity,activity.getPreferences(0), indexFd.getStartOffset(), assetsFd.getStartOffset(), getApkPath(), mainExpPath, patchExpPath);
			Log.d("LIGHTNING", "");

			if (err == null) {
				Log.d("LIGHTNING", "lightInit finished");
				initView(width,height);
				instance = this;
			} else {
				mlUncaughtException(err, new String[]{});
			}

			Log.d("LIGHTNING", "alalaspizda");
		} catch (java.io.IOException e) {
			mlUncaughtException(e.getMessage(), new String[]{});
		}

		// FIXME: move it to payments init
		// bserv = new BillingService();
		// bserv.setContext(activity);
		// ResponseHandler.register(activity);
	}

	protected void initView(int width,int height) {
		//setEGLContextFactory(new LightEGLContextFactory());
		Log.d("LIGHTNING","create Renderer");
		setEGLContextClientVersion(2);
		renderer = new LightRenderer(width,height);
		setRenderer(renderer);
		setFocusableInTouchMode(true);
	}

	public String getUDID () {
		return uuid;
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


	ArrayList<Runnable> waitingEvents = new ArrayList();
	boolean paused = false;

	@Override
	public void queueEvent(Runnable r) {
		if (paused) waitingEvents.add(r);
		else super.queueEvent(r);
	}
		
	public void surfaceCreated(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceCreated");
		super.surfaceCreated(holder);
		paused = false;
		// push all events
		if (!waitingEvents.isEmpty()) {
			Iterator<Runnable> iter = waitingEvents.iterator();
			while (iter.hasNext()) {
				Runnable r = iter.next();
				super.queueEvent(r);
			}

			waitingEvents.clear();
		};
	}

	public void surfaceDestroyed(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceDestroyed");
		super.surfaceDestroyed(holder);
		super.queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.nativeSurfaceDestroyed();
			}
		});
		paused = true;
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
		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleOnResume();
			}
		});
		//super.onResume();
	}

	public void onDestroy() {
		Log.d("LIGHTNING","VIEW.onDestroy");
		//lightFinalize();
		Process.killProcess(Process.myPid());
	}

	private class TouchHistoryItem {
		public float x;
		public float y;

		public TouchHistoryItem(float x, float y) {
			this.x = x;
			this.y = y;
		}
	}

	private HashMap<Integer,TouchHistoryItem> touchHistory = new HashMap<Integer,TouchHistoryItem>();

	private float truncate(float f) {
		return (new Double(f >= 0 ? Math.floor(f) : Math.ceil(f))).floatValue();
	}

	public boolean onTouchEvent(final MotionEvent event) {
		if (!isEnabled()) return true;

		//Log.d("LIGHTNING","Touch event");

		dumpMotionEvent(event);

		final int idx;
		final int id;
		final float x;
		final float y;

		TouchHistoryItem hi;

		switch (event.getActionMasked()) {

			case MotionEvent.ACTION_MOVE:
				final int size = event.getPointerCount();
				final int[] ids = new int[size];
				final float[] xs = new float[size];
				final float[] ys = new float[size];
				final int[] phases = new int[size];
				boolean moved = false;
				//final boolean hh = event.getHistorySize() > 0;

				for (int i = 0; i < size; i++) {
					ids[i] = event.getPointerId(i);
					xs[i] = truncate(event.getX(i));
					ys[i] = truncate(event.getY(i));

					hi = touchHistory.get(event.getPointerId(i));

					if (hi == null || Math.abs(hi.x - xs[i]) > 10 || Math.abs(hi.y - ys[i]) > 10) {
						if (hi == null) {
							hi = new TouchHistoryItem(xs[i], ys[i]);
							touchHistory.put(ids[i], hi);
						} else {
							hi.x = xs[i];
							hi.y = ys[i];
						}

						phases[i] = 1;
						moved = true;
					} else {
						phases[i] = 2;
					}
				};

				// we need to skip touches without changes of position

				Log.d("LIGHTNING", "moved " + (moved ? "true" : "false"));

				if (moved) {
					queueEvent(new Runnable() {
						@Override
						public void run() {
							renderer.fireTouches(ids, xs, ys,phases);
						}
					});
				}

				break;


			case MotionEvent.ACTION_DOWN:
				// there are only one finger on the screen
				id = event.getPointerId(0);
				x = event.getX(0);
				y = event.getY(0);
				touchHistory.put(id, new TouchHistoryItem(x, y));

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
				touchHistory.remove(idUp);

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
				touchHistory.put(id, new TouchHistoryItem(x, y));

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouch(id,x,y,0);
					}
				});
				break;

			case MotionEvent.ACTION_POINTER_UP:
				idx = event.getActionIndex();
				id = event.getPointerId(idx);
				x = event.getX(idx);
				y = event.getY(idx);
				touchHistory.remove(id);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.fireTouch(id,x,y,3);
					}
				});
				break;

			case MotionEvent.ACTION_CANCEL:
				touchHistory.clear();

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
			sb.append("<");
			for (int h = 0; h < event.getHistorySize (); h++) {
				sb.append((int)event.getHistoricalX(i,h)).append(",").append((int)event.getHistoricalY(i,h));
				if (h + 1 < event.getHistorySize()) sb.append(";");
			};
			sb.append(">");
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


	private native String lightInit(LightActivity activity,SharedPreferences p, long indexOffset, long assetsOffset, String assetsPath, String mainExpPath, String patchExpPath);
	private native void lightFinalize();

	/*
	public void requestPurchase(String prodId) {
		bserv.requestPurchase(prodId);
	}

	public void confirmNotif(String notifId) {
		bserv.confirmNotif(notifId);
	}	

	public void restoreTransactions() {
		bserv.restoreTransactions();
	}
	
	public void initBillingServ() {
		bserv.requestPurchase("android.test.purchased");
	}
	*/

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
		String label = ai.loadLabel(c.getPackageManager ()).toString() + "(android, " + activity.getString(R.string.screen) + ", " + activity.getString(R.string.density) + ")";
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
		body.append("\n------------------\n");
		body.append("gl extensions: " + glExts() + "\n");
		uri.append("&body=" + Uri.encode(body.toString()));
		Log.d("LIGHTNING","URI: " + uri.toString());
		Intent sendIntent = new Intent(Intent.ACTION_VIEW,Uri.parse(uri.toString ()));
		sendIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		c.startActivity(sendIntent);
	}

  public String mlGetLocale () {
		return Locale.getDefault().getLanguage();
	}

  public String mlGetInternalStoragePath () {
		Log.d("LIGHTNING", "LightView: mlgetStoragePath");
		return getContext().getFilesDir().getPath(); // FIXME: try to search external path first
	}

	public String mlGetStoragePath() {
		Log.d("LIGHTNING", "getStoragePath ");
		File storageDir = getContext().getExternalFilesDir(null);
		if (storageDir != null) return storageDir.getPath();
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


	public void downloadExpansions(final String pubKey) {
		Log.d("LIGHTNING", "extracting expansions");

	    for (XAPKFile xf : activity.getExpansions()) {
            String fileName = Helpers.getExpansionAPKFileName(activity, xf.mIsMain, xf.mFileVersion);

            Log.d("LIGHTNING", "checking " + fileName + "...");

            if (!Helpers.doesFileExist(activity, fileName, xf.mFileSize, false)) {
            	Log.d("LIGHTNING", fileName + " does not exists, start download service");

				getHandler().post(new Runnable() {
					@Override
					public void run() {
						activity.startExpansionDownloadService(pubKey);
					}
				});

            	return;
            }

            Log.d("LIGHTNING", "ok");
        }

        expansionsDownloaded();
	}

	private class ExpansionsCompleteCallbackRunnable implements Runnable {
		native public void run();
	}

	private class ExpansionsProgressCallbackRunnable implements Runnable {
		private long total;
		private long progress;
		private long timeRemain;

		public ExpansionsProgressCallbackRunnable(long total, long progress, long timeRemain) {
			this.total = total;
			this.progress = progress;
			this.timeRemain = timeRemain;
		}

		native public void run();
	}

	private class ExpansionsErrorCallbackRunnable implements Runnable {
		private String reason;

		public ExpansionsErrorCallbackRunnable(String reason) {
			this.reason = reason;
		}

		native public void run();
	}

	public void expansionsDownloaded() {
		Log.d("LIGHTNING", "expansions downloaded");
		queueEvent(new ExpansionsCompleteCallbackRunnable());
	}

	public void expansionsProgress(long total, long progress, long timeRemain) {
		Log.d("LIGHTNING", "expansions progress");
		queueEvent(new ExpansionsProgressCallbackRunnable(total, progress, timeRemain));
	}

	public void expansionsError(String reason) {
		Log.d("LIGHTNING", "expansions error: " + reason);
		queueEvent(new ExpansionsErrorCallbackRunnable(reason));
	}

	//////////////////////////////////
	// EXTERNAL IMAGE LAODER
	//////////////////////////////////
	private static class TexInfo {
		public int width;
		public int height;
		public int legalWidth;
		public int legalHeight;
		public byte[] data;
		public String format;
	}

	public TexInfo decodeImg(byte[] src) {
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
	/////////////////////////////////
	///// END EXTERNAL IMAGE LOADER
	/////////////////////////////////
	

	////////////////////
	// FILE DOWNLOADER
	////////////////////////
	

	private static class CurlDownloaderCallbackRunnable implements Runnable {
		private int req;

		public CurlDownloaderCallbackRunnable(int req) {
			this.req = req;
		}

		public native void run();
	}

	private static class CurlDownloaderErrorCallbackRunnable implements Runnable {
		private int req;
		private int errCode;
		private int errMes;

		public CurlDownloaderErrorCallbackRunnable(int req, int errCode, int errMes) {
			Log.d("LIGHTNING", "CurlDownloaderErrorCallbackRunnable");

			this.req = req;
			this.errCode = errCode;
			this.errMes = errMes;
		}

		public native void run();
	}

	public void curlDownloaderSuccess(int req) {
		Log.d("LIGHTNING", "curlDownloaderSuccess");
		queueEvent(new CurlDownloaderCallbackRunnable(req));
	}

	public void curlDownloaderError(int req, int errCode, int errMes) {
		Log.d("LIGHTNING", "curlDownloaderError " + errCode + " " + errMes);
		queueEvent(new CurlDownloaderErrorCallbackRunnable(req, errCode, errMes));
	}

	////////////////////
	// END FILE DOWNLOADER
	// ///////////////////

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

	public native String glExts();

	private ILightPayments payments;

	public void paymentsInit(boolean googleMarket, String key) {
		if (googleMarket) {
			payments = new LightGooglePayments(key);
		} else {
			payments = new LightAmazonPayments(LightActivity.instance);
		}

		payments.init();
	}

	public void paymentsInit(boolean googleMarket) {
		paymentsInit(googleMarket, null);	
	}

	public void paymentsPurchase(String sku) throws Error {
		if (payments == null) {
			throw new Error("payments not initialized");
		}

		payments.purchase(sku);
	}

	public void paymentsConsumePurchase(String purchaseToken) {
		payments.comsumePurchase(purchaseToken);
	}

	public void restorePurchases() {
		payments.restorePurchases();
	}

	public void showUrl(final String url) {
		LightView.instance.getHandler().post(new Runnable() {
			@Override
			public void run() {
				(new LightUrlDialog(getContext(), url)).show();
			}
		});
	}


	private ProgressDialog progressDialog;

	public void showNativeWait(final String message) {
		if (progressDialog != null) progressDialog.dismiss();
		post(new Runnable() {
			@Override
			public void run() {
				progressDialog = new ProgressDialog(getContext());
				progressDialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
				progressDialog.setIndeterminate(true);
				progressDialog.setCancelable(false);
				if (message != null) progressDialog.setMessage(message);
				progressDialog.show();
			}
		});
	}

	public void hideNativeWait() {
		if (progressDialog != null) progressDialog.dismiss();
	}
}
