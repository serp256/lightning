package ru.redspell.lightning;

import android.content.Intent;
import com.facebook.android.*;
import com.facebook.android.Facebook.*;
import com.facebook.android.AsyncFacebookRunner.*;

import java.io.FileNotFoundException;
import java.net.MalformedURLException;
import java.io.IOException;
import android.util.Log;
import android.os.Bundle;
import android.app.Activity;


public class AndroidFB {
	private static Facebook fb = null;
	private int onCompleteAuth;
	private static String authToken;
	private static Activity activity=null;


	public static void init (String app_id) {
	  Log.d("LIGHTNING", "Init FB " + app_id);
		fb = new Facebook(app_id);
	}

	public static void setActivity (Activity act) {
		activity = act;
	}

	public static void authorize (String [] permissions)  {
	  Log.d("LIGHTNING", "authorize with actibity" + activity.toString ()	);
		String permList = "PERSMISSIONS : \n";
		for (String str : permissions) {
			permList = permList + str + "\n";
		}
	  Log.d("LIGHTNING", permList );

    fb.authorize(activity, permissions,  new DialogListener() {
         @Override
         public void onComplete(Bundle values) {
           Log.d("LIGHTTEST", "onCOMPLETE"); 
		 			authToken = values.getString(Facebook.TOKEN);
           Log.d("LIGHTTEST", "authToken="+authToken); 
         }

         @Override
         public void onFacebookError(FacebookError error) { Log.d("LIGHTTEST","fb_error:" + error.toString ());}

         @Override
         public void onError(DialogError e) { Log.d("LIGHTTEST", "error" + e.toString ());}

         @Override
         public void onCancel() {Log.d("LIGHTTEST", "onCANCEL");}
     });

	}
}
