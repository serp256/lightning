package ru.redspell.lightning;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Bundle;

import com.facebook.FacebookException;
import com.facebook.Session;
import com.facebook.SessionState;
import com.facebook.widget.WebDialog;

import java.lang.Exception;
import java.lang.Runnable;
import java.util.ArrayList;
import java.util.Iterator;

import ru.redspell.lightning.utils.Log;

public class LightFacebook {
    private static String appId;
    public static Session session;

    private static class CamlCallbackRunnable implements Runnable {
        protected int callback;

        public CamlCallbackRunnable(int callback) {
            this.callback = callback;
        }

        @Override
        public native void run();
    }

    private static class CamlCallbackWithStringParamRunnable extends CamlCallbackRunnable {
        protected String param;

        public CamlCallbackWithStringParamRunnable(int callback, String param) {
            super(callback);
            this.param = param;
        }

        @Override
        public native void run();
    }

    private static class CamlCallbackWithStringArrayParamRunnable extends CamlCallbackRunnable {
        protected String[] param;

        public CamlCallbackWithStringArrayParamRunnable(int callback, String[] param) {
            super(callback);
            this.param = param;
        }

        @Override
        public native void run();
    }    

    private static class CamlNamedValueRunnable implements Runnable {
        protected String name;

        public CamlNamedValueRunnable(String name) {
            this.name = name;
        }

        @Override
        public native void run();
    }

    private static class CamlNamedValueWithStringParamRunnable extends CamlNamedValueRunnable {
        protected String param;

        public CamlNamedValueWithStringParamRunnable(String name, String param) {
            super(name);
            this.param = param;
        }

        @Override
        public native void run();
    }

    private static class CamlNamedValueWithStringAndValueParamsRunnable extends CamlNamedValueRunnable {
        protected String param1;
        protected int param2;

        public CamlNamedValueWithStringAndValueParamsRunnable(String name, String param1, int param2) {
            super(name);
            this.param1 = param1;
            this.param2 = param2;
        }

        @Override
        public native void run();
    }

    private static class ReleaseCamlCallbacksRunnable implements Runnable {
        protected int successCallback;
        protected int failCallback;

        public ReleaseCamlCallbacksRunnable(int successCallback, int failCallback) {
            this.successCallback = successCallback;
            this.failCallback = failCallback;
        }

        @Override
        public native void run();
    }

    private static Session openActiveSession(Activity activity, boolean allowLoginUI, Session.StatusCallback callback) {
        Session session = new Session.Builder(activity)
            .setApplicationId(appId)
            .build();

        if (SessionState.CREATED_TOKEN_LOADED.equals(session.getState()) || allowLoginUI) {
            Session.setActiveSession(session);
            session.openForRead(new Session.OpenRequest(activity).setCallback(callback));
            
            return session;
        }

        return null;
    }

    private static void fbError(Exception exception) {
        String mes = exception.getMessage();
        LightView.instance.queueEvent(new CamlNamedValueWithStringParamRunnable("fb_fail", mes != null ? mes : "unknow facebook error"));
    }

    public static void setAppId(String appId) {
        LightFacebook.appId = appId;
    }

    public static void connect() {
        Log.d("LIGHTNING", "connect call");

        LightFacebook.session = openActiveSession(LightActivity.instance, true, new Session.StatusCallback() {
            @Override
            public void call(Session session, SessionState state, Exception exception) {
                Log.d("LIGHTNING", "Session.StatusCallback call ");

                if (state.isOpened()) {
                    if (exception == null) {
                        Log.d("LIGHTNING", "login success");
                        LightView.instance.queueEvent(new CamlNamedValueRunnable("fb_success"));
                    } else {
                        Log.d("LIGHTNING", "login is opened with error");

                        fbError(exception);
                    }
                } else if (state == SessionState.CLOSED_LOGIN_FAILED) {
                    Log.d("LIGHTNING", "login failed");

                    if (LightFacebook.session != null) {
                        LightFacebook.session.closeAndClearTokenInformation();
                    }

                    fbError(exception);
                } else if (state == SessionState.CLOSED) {
                    Log.d("LIGHTNING", "session closed");

                    if (LightFacebook.session != null) {
                        LightFacebook.session.closeAndClearTokenInformation();
                    }

                    LightView.instance.queueEvent(new CamlNamedValueRunnable("fb_sessionClosed"));                    
                }
            }
        });
    }

    public static boolean loggedIn() {
        Log.d("LIGHTNING", "loggedIn call");

        if (session == null) {
            session = openActiveSession(LightActivity.instance, false, null);
        }

        Log.d("LIGHTNING", "session " + session);
        if (session != null) {
            Log.d("LIGHTNING", "session isOpened " + session.isOpened());
        }

        return session != null && session.isOpened();
    }

    public static String accessToken() {
        return session != null && session.isOpened() ? session.getAccessToken() : null;
    }

    public static boolean apprequest(final String title, final String message, final String recipient, final int successCallback, final int failCallback) {
        if (session == null || !session.isOpened()) return false;

        LightView.instance.post(new Runnable() {
            @Override
            public void run() {
                WebDialog.RequestsDialogBuilder bldr = new WebDialog.RequestsDialogBuilder(LightActivity.instance, session)
                    .setTitle(title)
                    .setMessage(message)
                    .setOnCompleteListener(new WebDialog.OnCompleteListener() {
                        @Override
                        public void onComplete(Bundle values, FacebookException error) {
                            Log.d("LIGHTNING", "onComplete");

                            if (error == null) {
                                Iterator iter = values.keySet().iterator();
                                ArrayList<String> to = new ArrayList<String>();
                                String[] toArr = new String[0];

                                while (iter.hasNext()) {
                                    String key = (String)iter.next();

                                    if (java.util.regex.Pattern.matches("to\\[\\d+\\]", key)) {
                                        to.add(values.get(key).toString());
                                    }
                                }

                                LightView.instance.queueEvent(new CamlCallbackWithStringArrayParamRunnable(successCallback, to.toArray(toArr)));
                            } else {
                                LightView.instance.queueEvent(new CamlCallbackWithStringParamRunnable(failCallback, error.getMessage()));
                            }
                            
                            LightView.instance.queueEvent(new ReleaseCamlCallbacksRunnable(successCallback, failCallback));
                        }
                    });
                
                if (recipient != null) {
                    bldr.setTo(recipient);                    
                }

                bldr.build().show();
            }
        });

        return true;
    }

    public static boolean graphrequest(final String path, final Bundle params, final int successCallback, final int failCallback) {
        if (session == null || !session.isOpened()) return false;

        LightView.instance.post(new Runnable() {
            @Override
            public void run() {
                new com.facebook.Request(session, path, params, com.facebook.HttpMethod.GET, new com.facebook.Request.Callback() {
                    @Override
                    public void onCompleted(com.facebook.Response response) {
                        com.facebook.FacebookRequestError error = response.getError();

                        if (error != null) {
                            Log.d("LIGHTNING", "error: " + error);

                            LightView.instance.queueEvent(new CamlCallbackWithStringParamRunnable(failCallback, error.getErrorMessage()));
                        } else {
                            String json = null;

                            if (response.getGraphObject() != null) {
                                json = response.getGraphObject().getInnerJSONObject().toString();
                            } else if (response.getGraphObjectList() != null) {
                                json = response.getGraphObjectList().getInnerJSONArray().toString();
                            }

                            Log.d("LIGHTNING", "json " + json);

                            if (json == null) {
                                LightView.instance.queueEvent(new CamlCallbackWithStringParamRunnable(failCallback, "something wrong with graphrequest response (not json object, not json objects list)"));
                            } else {
                                LightView.instance.queueEvent(new CamlNamedValueWithStringAndValueParamsRunnable("fb_graphrequestSuccess", json, successCallback));
                            }

                            LightView.instance.queueEvent(new ReleaseCamlCallbacksRunnable(successCallback, failCallback));
                        }
                    }
                }).executeAsync();
            }
        });

        return true;
    }
}