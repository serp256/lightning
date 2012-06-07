package ru.redspell.lightning; 

import android.app.Activity;
import android.opengl.GLSurfaceView;
import android.view.MotionEvent;
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
import android.media.SoundPool;
import android.content.Context;
import java.io.FileOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import android.os.Environment;


import ru.redspell.lightning.payments.BillingService;
import ru.redspell.lightning.payments.ResponseHandler;

public class LightView extends GLSurfaceView {

	private LightRenderer renderer;
	private int loader_id;
	private Handler uithread;
	private BillingService bserv;
	private File assetsDir;
	private URI assetsDirUri;

	public LightView(Activity activity) {
		super(activity);
		activity.requestWindowFeature(Window.FEATURE_NO_TITLE);
		activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
		DisplayMetrics dm = new DisplayMetrics();
		activity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		int width = dm.widthPixels;
		int height = dm.heightPixels;
		lightInit(activity.getPreferences(0));
		Log.d("LIGHTNING","lightInit finished");
		initView(width,height);

		bserv = new BillingService();
		bserv.setContext(activity);
		ResponseHandler.register(activity);
	}

	protected void initView(int width,int height) {
		setEGLContextClientVersion(2);
		Log.d("LIGHTNING","create Renderer");
		renderer = new LightRenderer(width,height);
		setFocusableInTouchMode(true);
		setRenderer(renderer);
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
			AssetFileDescriptor afd = getContext().getAssets().openFd(path);
			res = new ResourceParams(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());
		} catch (IOException e) {
			res =  null;
		}
		return res;
	}

	public void onPause(){
		Log.d("LIGHTNING", "onPause");

		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleOnPause();
			}
		});

		super.onPause();
	}

	public void onResume() {
		Log.d("LIGHTNING", "onResume");
		
		super.onResume();
		queueEvent(new Runnable() {
			@Override
			public void run() {
				renderer.handleOnResume();
			}
		});
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
	// а зачем эту хуйню запускать сперва в UI thread? Можно ведь сразу asynch task сделать!
	//
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
	}


	private native void lightInit(SharedPreferences p);

	public void requestPurchase(String prodId) {
		bserv.requestPurchase(prodId);
	}

	public void confirmNotif(String notifId) {
		bserv.confirmNotif(notifId);
	}	
	
	public void initBillingServ() {
		Log.d("LIGHTNING", "-----xyu");		
		//Log.d("LIGHTNING", "bserv.checkBillingSupported(): " + bserv.checkBillingSupported());
		// bserv.setContext();
		bserv.requestPurchase("android.test.purchased");
		Log.d("LIGHTNING", "-----pizda");
	}

/*	protected void cleanLocalStorage() {
		String[] names = fileList();

		for (String name : names) {
			File file = new File(path);
		}
	}*/

	// protected void traceAssets(String baseAsset, int indentSize) throws IOException {
	// 	Context cntxt = getContext();
	// 	String[] assets = cntxt.getAssets().list(baseAsset);
	// 	String indent = "";

	// 	for (int i = 0; i < indentSize; i++) {
	// 		indent += "\t";
	// 	}

	// 	for (String asset : assets) {			
	// 		Log.d("LIGHTNING", indent + asset);
	// 		traceAssets(baseAsset != "" ? baseAsset + "/" + asset : asset, indentSize + 1);			
	// 	}		
	// }

	protected void recExtractAssets(File dir) throws IOException {
		Context c = getContext();
		AssetManager am = c.getAssets();

		String subAssetsUri = assetsDirUri.relativize(dir.toURI()).toString();
		String[] subAssets = c.getAssets().list(subAssetsUri != "" ? subAssetsUri.substring(0, subAssetsUri.length() - 1) : subAssetsUri);

		for (String subAsset : subAssets) {
			File subAssetFile = new File(dir, subAsset);

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
				subAssetFile.mkdir();
				recExtractAssets(subAssetFile);
			}
		}
	}

	protected void traceFile(File file, int indentSize) {
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

	public void extractAssets() throws IOException {
		String state = Environment.getExternalStorageState();
		Context c = getContext();

		if (Environment.MEDIA_MOUNTED.equals(state)) {
			assetsDir = new File(c.getExternalFilesDir(null), "assets");

			if (assetsDir.isFile()) {
				assetsDir.delete();
			}

			if (!assetsDir.exists()) {
				assetsDir.mkdir();
			}
		} else {
		    assetsDir = c.getDir("assets", Context.MODE_PRIVATE);
		}

		assetsDirUri = assetsDir.toURI();

		Log.d("LIGHTNING", "_____________before");
		traceFile(assetsDir, 0);
		Log.d("LIGHTNING", "_____________before end");
		
		recExtractAssets(assetsDir);

		Log.d("LIGHTNING", "_____________after");
		traceFile(assetsDir, 0);
		Log.d("LIGHTNING", "_____________after end");


/*		if (assetsDir != null) {
			return;
		}

		Context c = getContext();
		assetsDir = c.getDir("assets", Context.MODE_PRIVATE);
		assetsDirUri = assetsDir.toURI();

		Log.d("LIGHTNING", "_____________before");
		traceFile(assetsDir, 0);
		Log.d("LIGHTNING", "_____________before end");


		recExtractAssets(assetsDir);


		Log.d("LIGHTNING", "_____________after");
		traceFile(assetsDir, 0);
		Log.d("LIGHTNING", "_____________after end");*/
	}
}