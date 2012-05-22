package ru.redspell.lightning;

import android.util.Log;
import android.os.Handler;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;
import android.opengl.GLSurfaceView;

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
		Log.d("LIGHTNING", "GL_EXTENSIONS: " + gl.glGetString(GL10.GL_EXTENSIONS));
		lightRendererInit(screenWidth,screenHeight);
		last = System.nanoTime();
	}

	public void onSurfaceChanged(GL10 gl, int w, int h) {  	
		Log.d("LIGHTNING","size: " + w + ":" + h);
		lightRendererChanged(w,h);
	}
    
	public void onDrawFrame(GL10 gl) {
    	
		long now = System.nanoTime();
		long interval = now - last;
		
		// should render a frame when onDrawFrame() is called
		// or there is a "ghost"
		lightRender(interval);   	
	
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
	
	*/

	public native void handleActionDown(int id, float x, float y);
	public native void handleActionUp(int id, float x, float y);
	public native void handleActionCancel(int[] id, float[] x, float[] y);
	public native void handleActionMove(int[] id, float[] x, float[] y);

	public void handleOnPause(){
		//nativeonpause();
	}
	
	public void handleOnResume(){
		//nativeonresume();
		last = System.nanoTime();
	}
	
	public static void setAnimationInterval(double interval){
		animationInterval = (long)(interval * NANOSECONDSPERSECOND);
	}


	private static native void lightRendererInit(int width, int height);
	private static native void lightRendererChanged(int width,int height);
	private static native void lightRender(long nanoseconds);

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
