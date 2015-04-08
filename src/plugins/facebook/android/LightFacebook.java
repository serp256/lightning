
package ru.redspell.lightning.plugins;
import ru.redspell.lightning.utils.Log;
import ru.redspell.lightning.Lightning;
import org.json.JSONObject;
import org.json.JSONArray;

class LightFacebook {
	public static void init (String appId) {
		Log.d ("LIGHTNING", "facebook_init: "+appId);
		ok = Odnoklassniki.createInstance(Lightning.activity, appId, appSecret, appKey);
	}
}

