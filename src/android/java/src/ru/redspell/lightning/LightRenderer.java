package ru.redspell.lightning;

import android.util.Log;
import android.os.Handler;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;
import android.opengl.GLSurfaceView;
//import ru.redspell.lightning.GLSurfaceView;
import android.os.Process;

public class LightRenderer implements GLSurfaceView.Renderer {

	private final static long NANOSECONDSPERSECOND = 1000000000L;
	private final static long NANOSECONDSPERMINISECOND = 1000000;
	private static long animationInterval = (long)(1.0 / 30 * NANOSECONDSPERSECOND);
	private long last;
	
	private int screenWidth;
	private int screenHeight;
	
	public LightRenderer(int width,int height) {
		super();
		screenWidth = width;
		screenHeight = height;
	}

	public void onSurfaceCreated(GL10 gl, EGLConfig config) { 	
		//Log.d("LIGHTNING", "GL_EXTENSIONS: " + gl.glGetString(GL10.GL_EXTENSIONS));
		Log.d("LIGHTNING","SURFACE CREATED tid: " + Process.myTid());
		nativeSurfaceCreated(screenWidth,screenHeight);
		last = System.nanoTime();

		String exts = gl.glGetString(GL10.GL_EXTENSIONS);

		
		Log.d("LIGHTNING", "exts: " + exts);
		Log.d("LIGHTNING", "pvr support: " + exts.contains("GL_IMG_texture_compression_pvrtc"));
		Log.d("LIGHTNING", "S3TC support: " + exts.contains("GL_OES_texture_compression_S3TC"));
		Log.d("LIGHTNING", "s3tc support: " + exts.contains("GL_EXT_texture_compression_s3tc"));
		Log.d("LIGHTNING", "dxt1 support: " + exts.contains("GL_EXT_texture_compression_dxt1"));
		Log.d("LIGHTNING", "dxt3 support: " + exts.contains("GL_EXT_texture_compression_dxt3"));
		Log.d("LIGHTNING", "dxt5 support: " + exts.contains("GL_EXT_texture_compression_dxt5"));
		
	}

	public void onSurfaceChanged(GL10 gl, int w, int h) {  	
		Log.d("LIGHTNING","size: " + w + ":" + h);
		nativeSurfaceChanged(w,h);
	}
    
	public void onDrawFrame(GL10 gl) {
    	
		// Log.d("LIGHTNING","onDraw Frame");
		long now = System.nanoTime();
		long interval = now - last;
		
		// should render a frame when onDrawFrame() is called
		// or there is a "ghost"
		nativeDrawFrame(interval);   	
	
		// fps controlling
		if (interval < animationInterval){ 
			try {
				// because we render it before, so we should sleep twice time interval
				Thread.sleep((animationInterval - interval) * 2 / NANOSECONDSPERMINISECOND);
			} catch (Exception e){}
		}	
		
		last = now;
	}
    

	/*
	public void handleactiondown(int id, float x, float y)
	{
		nativetouches(id, x, y);
	}
	
	public void handleactionup(int id, float x, float y)
	{
		nativetouchesend(id, x, y);
	}
	
	public void handleactioncancel(int[] id, float[] x, float[] y)
	{
		nativetouchescancel(id, x, y);
	}
	
	public void handleactionmove(int[] id, float[] x, float[] y)
	{
		nativetouchesmove(id, x, y);
	}
	
	public void handlekeydown(int keycode)
	{
		nativekeydown(keycode);
	}
	

	public native void handleActionDown(int id, float x, float y);
	public native void handleActionUp(int id, float x, float y);
	public native void handleActionCancel(int[] id, float[] x, float[] y);
	public native void handleActionMove(int[] id, float[] x, float[] y);

	*/

	public native void fireTouch(int id,float x, float y, int phase);
	public native void fireTouches(int[] ids,float[] xs, float[] ys, int[] phases);
	public native void cancelAllTouches();

	public native void handleOnPause();
	public native void handleOnResume();

	public native void handleBack();

	
	// public void handleOnPause(){
	// 	//nativeonpause();
	// }
	
	// public void handleOnResume(){
	// 	//nativeonresume();
	// 	last = System.nanoTime();
	// }
	
	public static void setAnimationInterval(double interval){
		animationInterval = (long)(interval * NANOSECONDSPERSECOND);
	}


	private static native void nativeSurfaceCreated(int width, int height);
	private static native void nativeSurfaceChanged(int width,int height);
	private static native void nativeDrawFrame(long nanoseconds);

	/*
	private static native void nativeTouchesBegin(int id, float x, float y);
	private static native void nativeTouchesEnd(int id, float x, float y);
	private static native void nativeTouchesMove(int[] id, float[] x, float[] y);
	private static native void nativeTouchesCancel(int[] id, float[] x, float[] y);
	private static native boolean nativeKeyDown(int keyCode);
	private static native void nativeRender();
	private static native void nativeInit(int w, int h);
	private static native void nativeOnPause();
	private static native void nativeOnResume();
	*/

}
