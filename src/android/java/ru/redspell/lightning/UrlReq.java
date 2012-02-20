package ru.redspell.lightning;

import android.os.Handler;
import android.opengl.GLSurfaceView;

// класс-обертка, чтобы обойти ограничение на параметры при работе с AsyncTask
public class UrlReq {
  protected String url;
  protected String method;
  protected String[][] headers;
  protected byte[] data;
  protected int loader_id;
  protected GLSurfaceView surface_view;
}
