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

    private static Session openActiveSession(final Activity activity, boolean allowLoginUI, final Session.StatusCallback callback) {
        final Session session = new Session.Builder(activity)
            .setApplicationId(appId)
            .build();

        if (SessionState.CREATED_TOKEN_LOADED.equals(session.getState()) || allowLoginUI) {
            Session.setActiveSession(session);

            LightView.instance.getHandler().post(new Runnable() {
                @Override
                public void run() {
                    session.openForRead(new Session.OpenRequest(activity).setCallback(callback));
                }
            });
            
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

    private static ArrayList readPerms = null;
    private static ArrayList publishPerms = null;

/*    private static Session.StatusCallback readPermsCallback =
        new Session.StatusCallback() {
            @Override
            public void call(Session session, SessionState state, Exception exception) {
                if (session.isOpened()) {
                    readPerms.clear();
                    readPerms = null;
                    session.removeCallback(this);
                    LightFacebook.session = session;

                    requestPublishPerms();
                }
            }
        };

    private static Session.StatusCallback publishPermsCallback =
        new Session.StatusCallback() {
            @Override
            public void call(Session session, SessionState state, Exception exception) {
                if (session.isOpened()) {
                    publishPerms.clear();
                    publishPerms = null;
                    session.removeCallback(this);
                    LightFacebook.session = session;

                    connectSuccess();
                }
            }            
        };*/

    private static final int EXTRA_PERMS_NOT_REQUESTED = 0;
    private static final int READ_PERMS_REQUESTED = 1;
    private static final int PUBLISH_PERMS_REQUESTED = 2;

    private static int extraPermsState = EXTRA_PERMS_NOT_REQUESTED;

    private static void requestPublishPerms() {
        Log.d("LIGHTNING", "requestPublishPerms");

        if (publishPerms != null && publishPerms.size() > 0) {
            Log.d("LIGHTNING", "requesting");

            Session session = Session.getActiveSession();
            // session.addCallback(publishPermsCallback);

            Session.NewPermissionsRequest request = new Session.NewPermissionsRequest(LightActivity.instance, publishPerms);
            extraPermsState = PUBLISH_PERMS_REQUESTED;
            session.requestNewPublishPermissions(request);
        } else {
            Log.d("LIGHTNING", "skip");
            extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
            connectSuccess();
        }
    }

    private static void requestReadPerms() {
        Log.d("LIGHTNING", "requestReadPerms");

        if (readPerms != null && readPerms.size() > 0) {
            Log.d("LIGHTNING", "requesting");
            Session session = Session.getActiveSession();
            // session.addCallback(readPermsCallback);

            Session.NewPermissionsRequest request = new Session.NewPermissionsRequest(LightActivity.instance, readPerms);
            extraPermsState = READ_PERMS_REQUESTED;
            session.requestNewReadPermissions(request);
        } else {
            Log.d("LIGHTNING", "skip");
            requestPublishPerms();
        }
    }

    private static void connectSuccess() {
        LightView.instance.queueEvent(new CamlNamedValueRunnable("fb_success"));
        LightFacebook.session = Session.getActiveSession();
    }

    private static String[] PUBLISH_PERMISSIONS_ARR = {
        "publish_actions",
        "publish_actions", 
        "ads_management",
        "create_event",
        "rsvp_event",
        "manage_friendlists",
        "manage_notifications",
        "manage_pages"
    };

    private static ArrayList<String> PUBLISH_PERMISSIONS = new ArrayList<String>(java.util.Arrays.asList(PUBLISH_PERMISSIONS_ARR));

    public static void connect(String[] perms) {
        Log.d("LIGHTNING", "connect call");

        for (int i = 0; i < perms.length; i++) {
            String perm = perms[i];
            Log.d("LIGHTNING", "additional permission " + perm);

            if (PUBLISH_PERMISSIONS.contains(perm)) {
                if (publishPerms == null) publishPerms = new ArrayList();
                publishPerms.add(perm);
            } else {
                if (readPerms == null) readPerms = new ArrayList();
                readPerms.add(perm);
            }
        }

        LightFacebook.session = openActiveSession(LightActivity.instance, true, new Session.StatusCallback() {
            @Override
            public void call(Session session, SessionState state, Exception exception) {
                Log.d("LIGHTNING", "Session.StatusCallback call " + state.toString());

                switch (state) {
                    case OPENED:
                        if (extraPermsState == EXTRA_PERMS_NOT_REQUESTED) {
                            requestReadPerms();    
                        }
                        
                        break;

                    case OPENED_TOKEN_UPDATED:
                        switch (extraPermsState) {
                            case READ_PERMS_REQUESTED:
                                readPerms.clear();
                                readPerms = null;
                                requestPublishPerms();

                                break;

                            case PUBLISH_PERMS_REQUESTED:
                                publishPerms.clear();
                                publishPerms = null;
                                extraPermsState = EXTRA_PERMS_NOT_REQUESTED;
                                connectSuccess();
                                
                                break;
                        }

                        break;

                    case CLOSED:
                        if (LightFacebook.session != null) {
                            LightFacebook.session.closeAndClearTokenInformation();
                        }

                        LightView.instance.queueEvent(new CamlNamedValueRunnable("fb_sessionClosed"));

                        break;

                    case CLOSED_LOGIN_FAILED:
                        if (LightFacebook.session != null) {
                            LightFacebook.session.closeAndClearTokenInformation();
                        }

                        fbError(exception);

                        break;

                    default:
                        break;
                }

/*                if (state.isOpened()) {
                    if (exception == null) {
                        Log.d("LIGHTNING", "session opened");
                        requestReadPerms();
                    } else {
                        Log.d("LIGHTNING", "login is opened with error");

                        fbError(exception);
                    }
                } else if (state == SessionState.CLOSED_LOGIN_FAILED) {
                    Log.d("LIGHTNING", "login failed " + exception.getMessage());

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
                }*/
            }
        });

        Log.d("LIGHTNING", "lightfacebook session " + (LightFacebook.session == null ? "null" : "not null"));
    }

	public static void disconnect () {
		Log.d("LIGHTNING", "disconnect call");
        
		if (session != null) {
			Log.d("LIGHTNING", "closeAndClear");
			session.closeAndClearTokenInformation ();
			Log.d("LIGHTNING", "close");
			session.close ();
			Log.d("LIGHTNING", "setActiveSession");
			session.setActiveSession(null);
			Log.d("LIGHTNING", "session null");
			session = null;
		}
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

    public static boolean apprequest(final String title, final String message, final String recipient, final String data, final int successCallback, final int failCallback) {
        if (session == null || !session.isOpened()) return false;

        LightView.instance.post(new Runnable() {
            @Override
            public void run() {
                WebDialog.RequestsDialogBuilder bldr = new WebDialog.RequestsDialogBuilder(LightActivity.instance, session)
                    .setTitle(title)
                    .setMessage(message)
										.setData(data)
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
								};

								LightView.instance.queueEvent(new CamlCallbackWithStringArrayParamRunnable(successCallback, to.toArray(toArr)));
                            } else {
								String msg = error.getMessage ();
								Log.d("LIGHTNING","error: " + error + ", message: " + error.getMessage ());
								LightView.instance.queueEvent(new CamlCallbackWithStringParamRunnable(failCallback, msg != null ? msg : error.toString()));
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
                new com.facebook.Request(session, path, params, params.size() == 0 ? com.facebook.HttpMethod.GET : com.facebook.HttpMethod.POST, new com.facebook.Request.Callback() {
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
