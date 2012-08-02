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
import android.content.SharedPreferences;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;
import android.content.Intent;
import android.media.SoundPool;
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
import android.os.AsyncTask;
import android.content.pm.PackageManager.NameNotFoundException;

import ru.redspell.lightning.payments.BillingService;
import ru.redspell.lightning.payments.ResponseHandler;

import android.media.MediaPlayer;
import android.media.AudioManager;
import android.os.Process;


public class LightView extends GLSurfaceView {

	private class ExtractAssetsTask extends AsyncTask<Void, Void, File> {
		//private File assetsDir;
		private URI assetsDirUri;
		private String ver;

		private void recExtractAssets(File dir) throws IOException {
			Log.d("LIGHTNING", "recExtractAssets call for " + dir.getPath());

			Context c = getContext();
			AssetManager am = c.getAssets();

			String subAssetsUri = assetsDirUri.relativize(dir.toURI()).toString();

			Log.d("LIGHTNING", "xyupizda1: " + subAssetsUri);

			String[] subAssets = c.getAssets().list(subAssetsUri != "" ? subAssetsUri.substring(0, subAssetsUri.length() - 1) : subAssetsUri);

			Log.d("LIGHTNING", "xyupizda2");

			for (String subAsset : subAssets) {
				File subAssetFile = new File(dir, subAsset);

				Log.d("LIGHTNING", "extracting " + assetsDirUri.relativize(subAssetFile.toURI()).toString());

				try {
					InputStream in = am.open(assetsDirUri.relativize(subAssetFile.toURI()).toString());

					subAssetFile.createNewFile();
					
					FileOutputStream out = new FileOutputStream(subAssetFile);
					byte[] buf = new byte[in.available()];

					in.read(buf, 0, in.available());
					out.write(buf, 0, buf.length);
					
					in.close();
					out.close();
				} catch (FileNotFoundException e) {
					Log.d("LIGHTNING", "directory");

					subAssetFile.mkdir();

					Log.d("LIGHTNING", "xyu");

					recExtractAssets(subAssetFile);
				}
			}
		}

		private void traceFile(File file, int indentSize) {
			String indent = "";

			for (int i = 0; i < indentSize; i++) {
				indent += "\t";
			}

			Log.d("LIGHTNING", indent + file.getAbsolutePath());

			if (file.isDirectory()) {
				File[] files = file.listFiles();

				for (File f : files) {
					traceFile(f, indentSize + 1);
				}
			}
		}

		private void extractAssets(File assetsDir) throws IOException {
			assetsDirUri = assetsDir.toURI();
			cleanDir(assetsDir);
			recExtractAssets(assetsDir);
			(new File(assetsDir, ver)).createNewFile();
		}

		private void cleanDir(File dir) {
			if (dir.isDirectory()) {
				for (File f : dir.listFiles()) {
					cleanDir(f);
					f.delete();
				}
			}
		}

		private File getExternalAssetsPath() {
			return new File(getContext().getExternalFilesDir(null), "assets");
		}

		private File getInternalAssetsPath() {
			return getContext().getDir("assets", Context.MODE_PRIVATE);
		}

		private void extractAssetsToExternal(File assetsDir) throws IOException {
			String state = Environment.getExternalStorageState();

			if (!Environment.MEDIA_MOUNTED.equals(state)) {
				throw new IOException("External stotage is unavailable");
			}

			if (!assetsDir.exists()) {
				assetsDir.mkdir();
			}

			extractAssets(assetsDir);
		}

		private void extractAssetsToInternal(File assetsDir) throws IOException {
			Context c = getContext();
			extractAssets(assetsDir);
		}

		protected File doInBackground(Void... params) {
			File internalAssetsPath = getInternalAssetsPath();
			File externalAssetsPath = getExternalAssetsPath();

			try {
				Context c = getContext();				
				ver = c.getPackageManager().getPackageInfo(c.getPackageName(), 0).versionName;

				if ((new File(externalAssetsPath, ver)).exists()) {
					Log.d("LIGHTNING", "assets already extracted to external storage");
					return externalAssetsPath;
				}

				if ((new File(internalAssetsPath, ver).exists())) {
					Log.d("LIGHTNING", "assets already extracted to internal storage");
					return internalAssetsPath;
				}
			
				Log.d("LIGHTNING", "trying to extract assets to external stotage...");
				extractAssetsToExternal(externalAssetsPath);
				Log.d("LIGHTNING", "success");

				return externalAssetsPath;
			} catch (IOException e) {
				Log.d("LIGHTNING", "failed, try to extract assets to internal storage...");

				cleanDir(externalAssetsPath);

				try {
					extractAssetsToInternal(internalAssetsPath);
					Log.d("LIGHTNING", "success");

					return internalAssetsPath;
				} catch (IOException e1) {
					Log.e("LIGHTNING", "failed, cannot use any kind of storate for assets extraction");
					cleanDir(internalAssetsPath);
				}
			} catch (NameNotFoundException nnfe) {
				Log.e("LIGHTNING", "NameNotFoundException");
			}

			return null;
		}

		protected void onPostExecute(File res) {
			assetsExtracted(res != null ? res.getAbsolutePath() : null);
		}
	}

	private LightRenderer renderer;
	private int loader_id;
	private Handler uithread;
	private BillingService bserv;
	public AndroidFB fb; 
	//private File assetsDir;

	public static LightView instance;
	
	public Activity activity;

	public LightView(Activity _activity) {
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

		bserv = new BillingService();
		bserv.setContext(activity);
		ResponseHandler.register(activity);
		fb = new AndroidFB();
		fb.setView (this);
	}

	protected void initView(int width,int height) {
		setEGLContextClientVersion(2);
		Log.d("LIGHTNING","create Renderer");
		renderer = new LightRenderer(width,height);
		setFocusableInTouchMode(true);
		setRenderer(renderer);
	}

	public void surfaceCreated(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceCreated");
		super.surfaceCreated(holder);
	}

	public void surfaceDestroyed(SurfaceHolder holder) {
		Log.d("LIGHTNING","surfaceDestroyed");
		super.surfaceDestroyed(holder);
	}

	public int getSoundId(String path, SoundPool sndPool) throws IOException {
		if (path.charAt(0) == '/') {
			return sndPool.load(path, 1);
		}

		return sndPool.load(getContext().getAssets().openFd(path), 1);
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
		lightFinalize();
	}


	public boolean onTouchEvent(final MotionEvent event) {
		Log.d("LIGHTNING","Touch event");

		// these data are used in ACTION_MOVE and ACTION_CANCEL
		dumpMotionEvent(event);
		final int pointerNumber = event.getPointerCount();
		final int[] ids = new int[pointerNumber];
		final float[] xs = new float[pointerNumber];
		final float[] ys = new float[pointerNumber];

		for (int i = 0; i < pointerNumber; i++) {
			ids[i] = event.getPointerId(i);
			xs[i] = event.getX(i);
			ys[i] = event.getY(i);
		}

		switch (event.getAction() & MotionEvent.ACTION_MASK) {

			case MotionEvent.ACTION_POINTER_DOWN:
				final int idPointerDown = event.getAction() >> MotionEvent.ACTION_POINTER_INDEX_SHIFT;
				final float xPointerDown = event.getX(idPointerDown);
				final float yPointerDown = event.getY(idPointerDown);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionDown(idPointerDown, xPointerDown, yPointerDown);
					}
				});
				break;

			case MotionEvent.ACTION_DOWN:
				// there are only one finger on the screen
				final int idDown = event.getPointerId(0);
				final float xDown = event.getX(idDown);
				final float yDown = event.getY(idDown);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionDown(idDown, xDown, yDown);
					}
				});
				break;

			case MotionEvent.ACTION_MOVE:
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionMove(ids, xs, ys);
					}
				});
				break;

			case MotionEvent.ACTION_POINTER_UP:
				final int idPointerUp = event.getAction() >> MotionEvent.ACTION_POINTER_ID_SHIFT;
				final float xPointerUp = event.getX(idPointerUp);
				final float yPointerUp = event.getY(idPointerUp);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionUp(idPointerUp, xPointerUp, yPointerUp);
					}
				});
				break;

			case MotionEvent.ACTION_UP:  
				// there are only one finger on the screen
				final int idUp = event.getPointerId(0);
				final float xUp = event.getX(idUp);
				final float yUp = event.getY(idUp);

				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionUp(idUp, xUp, yUp);
					}
				});
				break;

			case MotionEvent.ACTION_CANCEL:
				queueEvent(new Runnable() {
					@Override
					public void run() {
						renderer.handleActionCancel(ids, xs, ys);
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

	public void extractAssets() {
		Log.d("LIGHTNING", "lightview extractAssets call");

		getHandler().post(new Runnable() {
			public void run() {
				Log.d("LIGHTNING", "Runnable run call");
				new ExtractAssetsTask().execute();		
			}
		});
	}

	private native void assetsExtracted(String assetsDir);


  public void openURL(String url){
		Context c = getContext();
    Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
		c.startActivity(i);
	}

  private String supportEmail = "mail@redspell.ru";
	public void setSupportEmail(String d){
		supportEmail = d;
	}

	public void addExceptionInfo(String d) {
    openURL("mailto:".concat(supportEmail).concat("?subject=test&body=wtf"));
	}

  public String mlGetLocale () {
		return Locale.getDefault().getLanguage();
	}

  public String mlGetStoragePath () {
		Log.d("LIGHTNING", "LightView: mlgetStoragePath");
		return getContext().getFilesDir().getPath();
	}


	private class LightMediaPlayer extends MediaPlayer {
		private class CamlCallbackCompleteListener implements MediaPlayer.OnCompletionListener {
			private int camlCb;

			public CamlCallbackCompleteListener(int cb) {
				camlCb = cb;
			}

			public native void onCompletion(MediaPlayer mp);
		}

		public void start(int cb) {
			setOnCompletionListener(new CamlCallbackCompleteListener(cb));
			start();
		}
	}

	public MediaPlayer createMediaPlayer(String path) throws IOException {
		AssetFileDescriptor afd = getContext().getAssets().openFd(path);

		MediaPlayer mp = new LightMediaPlayer();

		Log.d("LIGHTNING", path);

		mp.setAudioStreamType(AudioManager.STREAM_MUSIC);
		mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());

		return mp;
	}
}
