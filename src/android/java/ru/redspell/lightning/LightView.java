package ru.redspell.lightning; 

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.view.MotionEvent;
import android.util.Log;
import java.io.InputStream;
import java.io.BufferedInputStream;
import java.io.IOException;


import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import android.content.res.AssetManager;
import android.content.res.AssetFileDescriptor;

public class LightView extends GLSurfaceView {

	private LightRenderer renderer;

	public LightView(Context context,int width,int height) {
		super(context);
		initView(width,height);
	}

	protected void initView(int width,int height) {
		lightInit();
		renderer = new LightRenderer(width,height);
		setFocusableInTouchMode(true);
		setRenderer(renderer);
	}


	public ResourceParams getResource(String path) {
		ResourceParams res;
		try {
			AssetFileDescriptor afd = getContext().getAssets().openFd(path);
			res = new ResourceParams(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());
		} catch (IOException e) {res =  null;};
		return res;
	}

	 public void onPause(){
		 queueEvent(new Runnable() {
			 @Override
			 public void run() {
				 renderer.handleOnPause();
			 }
		 });

		 super.onPause();
	 }
	    
	 public void onResume() {
		 super.onResume();
		 queueEvent(new Runnable() {
			 @Override
			 public void run() {
				 renderer.handleOnResume();
			 }
		 });
	 }
			 

	public boolean onTouchEvent(final MotionEvent event) {
		Log.d("EVENT","Touch event");

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
		 Log.d("EVENT", sb.toString());
	}

	private native void lightInit();
}

