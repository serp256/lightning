package ru.redspell.lightning.payments.google;

import android.app.PendingIntent;
import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;


import com.android.vending.billing.IInAppBillingService;

import ru.redspell.lightning.LightActivity;
import ru.redspell.lightning.LightView;
import ru.redspell.lightning.payments.ILightPayments;
import ru.redspell.lightning.payments.LightPaymentsCamlCallbacks;
import ru.redspell.lightning.utils.Log;

import java.lang.Error;
import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;

import org.json.JSONObject;

public class LightGooglePayments implements ILightPayments {
    public static final int BILLING_RESPONSE_RESULT_OK = 0;
    public static final int BILLING_RESPONSE_RESULT_USER_CANCELED = 1;
    public static final int BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE = 3;
    public static final int BILLING_RESPONSE_RESULT_ITEM_UNAVAILABLE = 4;
    public static final int BILLING_RESPONSE_RESULT_DEVELOPER_ERROR = 5;
    public static final int BILLING_RESPONSE_RESULT_ERROR = 6;
    public static final int BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED = 7;
    public static final int BILLING_RESPONSE_RESULT_ITEM_NOT_OWNED = 8;

    public static final int BILLING_API_VER = 3;
    public static final int REQUEST_CODE = 1001;

    public static LightGooglePayments instance;

    private IInAppBillingService mService;
    private ServiceConnection mServiceConn;
    private HashMap<String,String> developerPayloadSkuMap = new HashMap<String,String>();
    private Random rand;
    private String key;

    public LightGooglePayments(String key) {
        this();
        this.key = key;
    }

    public LightGooglePayments() {
        Log.d("LIGHTNING", "LightGooglePayments call");

        instance = this;

        SecureRandom sRand = new SecureRandom();
        byte[] bytes = new byte[Long.SIZE / 8];
        ByteBuffer bBuf = ByteBuffer.allocate(bytes.length);

        sRand.nextBytes(bytes);
        bBuf.put(bytes);
        // rand = new Random(bBuf.getLong());
        rand = new Random();

        Log.d("LIGHTNING", "LightGooglePayments end");
    }

    @Override
    public void init() {
        Log.d("LIGHTNING", "init call");

        Context cntxt = LightActivity.instance;

        if (cntxt == null) {
            throw new Error("call LightGooglePayments.init only after LightActivity instantiated");
        }

        mServiceConn = new ServiceConnection() {
           @Override
           public void onServiceDisconnected(ComponentName name) {
               mService = null;
           }

           @Override
           public void onServiceConnected(ComponentName name, IBinder service) {
                Log.d("LIGHTNING", "service binded");
                mService = IInAppBillingService.Stub.asInterface(service);
           }
        };

        Log.d("LIGHTNING", "binding service call");
        cntxt.bindService(new Intent("com.android.vending.billing.InAppBillingService.BIND"), mServiceConn, Context.BIND_AUTO_CREATE);
    }

    @Override
    public void purchase(String sku) {
        try {
            if (mService == null) {
                throw new Error("Google billing service not initiated");
            }

            String developerPayload;

            do {
                developerPayload = (new Integer(rand.nextInt(1000))).toString();  
            } while (developerPayloadSkuMap.containsKey(developerPayload));

            developerPayloadSkuMap.put(developerPayload, sku);
            Bundle buyIntentBundle = mService.getBuyIntent(BILLING_API_VER, LightActivity.instance.getPackageName(), sku, "inapp", developerPayload);

            if (buyIntentBundle == null) {
                Log.d("LIGHTNING", "buyIntentBundle null");
            } else {
                Log.d("LIGHTNING", "buyIntentBundle not null");
            }

            PendingIntent pendingIntent = buyIntentBundle.getParcelable("BUY_INTENT");

            if (pendingIntent == null || pendingIntent.getIntentSender() == null) {
                LightPaymentsCamlCallbacks.fail(sku, "looks like '" + sku + "' already purchased and transaction is not commited");
                return;
            }

            LightActivity.instance.startIntentSenderForResult(pendingIntent.getIntentSender(), REQUEST_CODE, new Intent(), Integer.valueOf(0), Integer.valueOf(0), Integer.valueOf(0));            
        } catch (android.os.RemoteException e) {
            LightPaymentsCamlCallbacks.fail(sku, "android.os.RemoteException exception");
        } catch (android.content.IntentSender.SendIntentException e) {
            LightPaymentsCamlCallbacks.fail(sku, "android.content.IntentSender.SendIntentException exception");
        }
    }

    @Override
    public void comsumePurchase(final String purchaseToken) {
        // should run in view thread? and what about response?
        LightView.instance.getHandler().post(new Runnable() {
            public void run() {
                try {
                    mService.consumePurchase(BILLING_API_VER, LightActivity.instance.getPackageName(), purchaseToken);
                } catch (android.os.RemoteException e) {
                    LightPaymentsCamlCallbacks.fail("none", "android.os.RemoteException exception");
                }
            }
        });
    }

    @Override
    public void restorePurchases() {
        Log.d("LIGHTNING", "restorePurchases call");

        if (mService == null) {
            throw new Error("Google billing service not initiated");
        }

        String continuationToken = null;

        try {
            do {
                Bundle ownedItems = mService.getPurchases(BILLING_API_VER, LightActivity.instance.getPackageName(), "inapp", continuationToken);
                int responseCode = ownedItems.getInt("RESPONSE_CODE");

                if (responseCode == BILLING_RESPONSE_RESULT_OK) {
                    ArrayList<String> ownedSkus = ownedItems.getStringArrayList("INAPP_PURCHASE_ITEM_LIST");
                    ArrayList<String> purchaseDataList = ownedItems.getStringArrayList("INAPP_PURCHASE_DATA_LIST");
                    ArrayList<String> signatureList = ownedItems.getStringArrayList("INAPP_DATA_SIGNATURE");
                    continuationToken = ownedItems.getString("INAPP_CONTINUATION_TOKEN");

                    Log.d("LIGHTNING", "purchaseDataList.size() " + purchaseDataList.size());

                    for (int i = 0; i < purchaseDataList.size(); ++i) {
                        String purchaseData = purchaseDataList.get(i);
                        String signature = signatureList != null ? signatureList.get(i) : "";
                        String sku = ownedSkus.get(i);

                        JSONObject o = new JSONObject(purchaseData);
                        String token = o.optString("token", o.optString("purchaseToken"));

                        LightPaymentsCamlCallbacks.success(sku, token, purchaseData, signature, true);
                    }
                }  
            } while (continuationToken != null);            
        } catch (android.os.RemoteException e) {
            LightPaymentsCamlCallbacks.fail("none", "android.os.RemoteException exception");
        } catch (org.json.JSONException e) {
            LightPaymentsCamlCallbacks.fail("none", "org.json.JSONException exception");
        }
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        try {
            Log.d("LIGHTNING", "onActivityResult call");

            if (requestCode == REQUEST_CODE) {           
                int responseCode = data.getIntExtra("RESPONSE_CODE", 0);
                String purchaseData = data.getStringExtra("INAPP_PURCHASE_DATA");
                String dataSignature = data.getStringExtra("INAPP_DATA_SIGNATURE");

                JSONObject o = null;
                String sku = null;
                String developerPayload = null;

                String failReason = null;

                if (resultCode != Activity.RESULT_OK) {
                    failReason = "activity result error " + resultCode;
                } else if (responseCode != BILLING_RESPONSE_RESULT_OK) {
                    failReason = "response error " + responseCode;
                } else {
                    o = new JSONObject(purchaseData);
                    sku = o.optString("productId");
                    developerPayload = o.optString("developerPayload");

                    if (!developerPayloadSkuMap.containsKey(developerPayload)) {
                        failReason = "unknown developerPayload " + developerPayload;
                    } else if (key != null && !LightGoogleSecurity.verifyPurchase(key, purchaseData, dataSignature)) {
                        failReason = "signature verification failed";
                    }
                }

                if (failReason != null) {
                    Log.d("LIGHTNING", "fail, reason: " + failReason);
                    LightPaymentsCamlCallbacks.fail(developerPayload != null ? developerPayloadSkuMap.get(developerPayload) : "none", failReason);
                } else {                    
                    String token = o.optString("token", o.optString("purchaseToken"));

                    Log.d("LIGHTNING", "success " + sku + " " + token + " " + purchaseData + " " + dataSignature);
                    LightPaymentsCamlCallbacks.success(sku, token, purchaseData, dataSignature, false);
                }

                developerPayloadSkuMap.remove(developerPayload);
            }
        } catch (org.json.JSONException e) {
            LightPaymentsCamlCallbacks.fail("none", "org.json.JSONException exception");
        }
    }

    public void contextDestroyed(Context context) {
        if (mServiceConn != null) {
            context.unbindService(mServiceConn);
        }
    }
}