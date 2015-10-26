package ru.redspell.lightning;

import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.ConnectionResult;
import ru.redspell.lightning.utils.Log;

public class GooglePlayServices {
    private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;

    private static boolean checked = false;
    private static boolean available = false;

    public static boolean available() {
        if (!checked) {
            checked = true;

            int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(Lightning.activity);

            if (resultCode != ConnectionResult.SUCCESS) {

							if (resultCode != ConnectionResult.SERVICE_MISSING) {
                if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
                    GooglePlayServicesUtil.getErrorDialog(resultCode, Lightning.activity, PLAY_SERVICES_RESOLUTION_REQUEST).show();
                };
							}
							available = false;
            }
						else {
							available = true;
						}
        }

        return available;
    }
}
