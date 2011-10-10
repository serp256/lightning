package ru.redspell.lightning;

import android.os.Handler;

// класс-обертка, чтобы обойти ограничение на параметры при работе с AsyncTask
public class UrlReq {
  protected String url;
  protected String method;
  protected String[][] headers;
  protected String data;
  protected int loader_id;
	protected Handler mainthread;
}
