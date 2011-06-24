package ru.redspell.lightning;

import android.util.Log;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;
import android.opengl.GLSurfaceView;

public class LightRenderer implements GLSurfaceView.Renderer {

	private final static long NANOSECONDSPERSECOND = 1000000000L;
	private final static long NANOSECONDSPERMINISECOND = 1000000;
	private static long animationInterval = (long)(1.0 / 30 * NANOSECONDSPERSECOND);
	private long last;
	

	private float screenWidth;
	private float screenHeight;
	public LightRenderer(float width,float height) {
		super();
		screenWidth = width;
		screenHeight = height;
	}

	public void onSurfaceCreated(GL10 gl, EGLConfig config) { 	
		lightRendererInit(screenWidth,screenHeight);
		last = System.nanoTime();
	}

	public void onSurfaceChanged(GL10 gl, int w, int h) {  	
		gl.glViewport(0,0,w,h);
		Log.d("LightRenderer", "onSurfaceChanged");
	}
    
	public void onDrawFrame(GL10 gl) {
    	
		long now = System.nanoTime();
		long interval = now - last;
		
		// should render a frame when onDrawFrame() is called
		// or there is a "ghost"
		lightRender();   	
	
		// fps controlling
		if (interval < animationInterval){ 
			try {
				// because we render it before, so we should sleep twice time interval
				Thread.sleep((animationInterval - interval) * 2 / NANOSECONDSPERMINISECOND);
			} catch (Exception e){}
		}	
		
		last = now;
	}
    

	public void handleTouches(int id) {
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

	public void handleOnPause(){
		//nativeonpause();
	}
	
	public void handleOnResume(){
		//nativeonresume();
	}
	
	public static void setAnimationInterval(double interval){
		animationInterval = (long)(interval * NANOSECONDSPERSECOND);
	}


	private static native void lightRendererInit(float width,float height);
	private static native void lightRender();

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
