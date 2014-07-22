package ru.redspell.lightning.payments.google;

import ru.redspell.lightning.Lightning;

import android.app.PendingIntent;
import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;


import com.android.vending.billing.IInAppBillingService;
import ru.redspell.lightning.payments.PaymentsCallbacks;
import ru.redspell.lightning.utils.Log;

import java.lang.Error;
import java.nio.ByteBuffer;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;

import org.json.JSONObject;
import ru.redspell.lightning.IUiLifecycleHelper;

public class Payments {
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

    public static Payments instance;

    private IInAppBillingService mService;
    private ServiceConnection mServiceConn;
    private HashMap<String,String> developerPayloadSkuMap = new HashMap<String,String>();
    private Random rand;
    private String key;

    public Payments(String key) {
        this();
        this.key = key;
    }

    public Payments() {
        instance = this;

        SecureRandom sRand = new SecureRandom();
        byte[] bytes = new byte[Long.SIZE / 8];
        ByteBuffer bBuf = ByteBuffer.allocate(bytes.length);

        sRand.nextBytes(bytes);
        bBuf.put(bytes);
        // rand = new Random(bBuf.getLong());
        rand = new Random();
    }

    ArrayList<Runnable> pendingRequests = new ArrayList();

    public void init(final String[] skus) {
        Context context = Lightning.activity;

        if (context == null) {
            throw new Error("call Payments.init only after activity instantiated");
        }

        mServiceConn = new ServiceConnection() {
           @Override
           public void onServiceDisconnected(ComponentName name) {
               mService = null;
           }

           @Override
           public void onServiceConnected(ComponentName name, IBinder service) {
                Log.d("LIGHTNING", "service binded, tid " + (new Integer(android.os.Process.myTid()).toString()));
                mService = IInAppBillingService.Stub.asInterface(service);

                (new SkuDetailsTask()).execute(skus);

                java.util.Iterator<Runnable> iter = pendingRequests.iterator();
                while (iter.hasNext()) {
                    Log.d("LIGHTNING", "running pending request");
                    iter.next().run();
                }

                pendingRequests.clear();

                Lightning.activity.addUiLifecycleHelper(new IUiLifecycleHelper() {
                    @Override
                    public void onCreate(Bundle savedInstanceState) {}
                    
                    @Override
                    public void onResume() {}
                    
                    @Override
                    public void onActivityResult(int requestCode, int resultCode, Intent data) {
                        try {
                            Log.d("LIGHTNING", "onActivityResult call");

                            if (data != null && requestCode == REQUEST_CODE) {           
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
                                                        } else {
                                                            int purchaseState = o.optInt("purchaseState",1);
                                                            if (purchaseState != 0) {
                                                                    failReason = "purchaseState is " + purchaseState;
                                                            } else if (key != null && !Security.verifyPurchase(key, purchaseData, dataSignature)) {
                                                                    failReason = "signature verification failed";
                                                            }
                                                        }
                                }

                                if (failReason != null) {
                                    Log.d("LIGHTNING", "fail, reason: " + failReason);
                                    PaymentsCallbacks.fail(developerPayload != null ? developerPayloadSkuMap.get(developerPayload) : "none", failReason);
                                } else {                    
                                    String token = o.optString("token", o.optString("purchaseToken"));

                                    Log.d("LIGHTNING", "success " + sku + " " + token + " " + purchaseData + " " + dataSignature);
                                    PaymentsCallbacks.success(sku, token, purchaseData, dataSignature, false);
                                }

                                developerPayloadSkuMap.remove(developerPayload);
                            }
                        } catch (org.json.JSONException e) {
                            PaymentsCallbacks.fail("none", "org.json.JSONException exception");
                        }
                    }
                    
                    @Override
                    public void onSaveInstanceState(Bundle outState) {}
                    
                    @Override
                    public void onPause() {}
                    
                    @Override
                    public void onStop() {}
                    
                    @Override
                    public void onDestroy() {}

                });
           }
        };

        Log.d("LIGHTNING", "binding service call");
        context.bindService(new Intent("com.android.vending.billing.InAppBillingService.BIND"), mServiceConn, Context.BIND_AUTO_CREATE);
    }

    public void purchase(final String sku) {
        try {
            if (mService == null) {
                Log.d("LIGHTNING", "adding purchase request to pendings");

                // throw new Error("Google billing service not initiated");
                pendingRequests.add(new Runnable() {
                    @Override
                    public void run() {
                        purchase(sku);
                    }
                });

                return;
            }

            String developerPayload;

            do {
                developerPayload = (new Integer(rand.nextInt(1000))).toString();  
            } while (developerPayloadSkuMap.containsKey(developerPayload));

            developerPayloadSkuMap.put(developerPayload, sku);
            Bundle buyIntentBundle = mService.getBuyIntent(BILLING_API_VER, Lightning.activity.getPackageName(), sku, "inapp", developerPayload);

            if (buyIntentBundle == null) {
                Log.d("LIGHTNING", "buyIntentBundle null");
            } else {
                Log.d("LIGHTNING", "buyIntentBundle not null");
            }

            PendingIntent pendingIntent = buyIntentBundle.getParcelable("BUY_INTENT");

            if (pendingIntent == null || pendingIntent.getIntentSender() == null) {
                PaymentsCallbacks.fail(sku, "looks like '" + sku + "' already purchased and transaction is not commited");
                return;
            }

            Lightning.activity.startIntentSenderForResult(pendingIntent.getIntentSender(), REQUEST_CODE, new Intent(), Integer.valueOf(0), Integer.valueOf(0), Integer.valueOf(0));            
        } catch (android.os.RemoteException e) {
            PaymentsCallbacks.fail(sku, "android.os.RemoteException exception");
        } catch (android.content.IntentSender.SendIntentException e) {
            PaymentsCallbacks.fail(sku, "android.content.IntentSender.SendIntentException exception");
        }
    }

    public void consumePurchase(final String purchaseToken) {
        Log.d("LIGHTNING", "comsumePurchase CALL");

        try {
            mService.consumePurchase(BILLING_API_VER, Lightning.activity.getPackageName(), purchaseToken);
        } catch (android.os.RemoteException e) {
            PaymentsCallbacks.fail("none", "android.os.RemoteException exception");
        }
    }

    public void restorePurchases() {
        Log.d("LIGHTNING", "restorePurchases call");

        if (mService == null) {
            // throw new Error("Google billing service not initiated");
            Log.d("LIGHTNING", "adding restorePurchases request to pendings");

            pendingRequests.add(new Runnable() {
                @Override
                public void run() {
                    restorePurchases();
                }
            });

            return;
        }

        String continuationToken = null;

        try {
            do {
                Bundle ownedItems = mService.getPurchases(BILLING_API_VER, Lightning.activity.getPackageName(), "inapp", continuationToken);
                int responseCode = ownedItems.getInt("RESPONSE_CODE");

                if (responseCode == BILLING_RESPONSE_RESULT_OK) {
                    ArrayList<String> ownedSkus = ownedItems.getStringArrayList("INAPP_PURCHASE_ITEM_LIST");
                    ArrayList<String> purchaseDataList = ownedItems.getStringArrayList("INAPP_PURCHASE_DATA_LIST");
                    ArrayList<String> signatureList = ownedItems.getStringArrayList("INAPP_DATA_SIGNATURE_LIST");
                    continuationToken = ownedItems.getString("INAPP_CONTINUATION_TOKEN");

                    Log.d("LIGHTNING", "purchaseDataList.size() " + purchaseDataList.size());

                    for (int i = 0; i < purchaseDataList.size(); ++i) {
                        String purchaseData = purchaseDataList.get(i);
                        JSONObject o = new JSONObject(purchaseData);
                        String token = o.optString("token", o.optString("purchaseToken"));
												int purchaseState = o.optInt("purchaseState",1);
												if (purchaseState == 0) {
													String signature = signatureList.get(i);
													if (key != null && !Security.verifyPurchase(key, purchaseData, signature)) continue;
													String sku = ownedSkus.get(i);
													PaymentsCallbacks.success(sku, token, purchaseData, signature, true);
												}
                    }
                }
            } while (continuationToken != null);            
        } catch (android.os.RemoteException e) {
            PaymentsCallbacks.fail("none", "android.os.RemoteException exception");
        } catch (org.json.JSONException e) {
            PaymentsCallbacks.fail("none", "org.json.JSONException exception");
        }
    }

    public void contextDestroyed(Context context) {
        if (mServiceConn != null) {
            context.unbindService(mServiceConn);
        }
    }

    private class SkuDetailsTask extends android.os.AsyncTask<String, Void, Bundle> {
        @Override
        protected Bundle doInBackground(String... skus) {
            Bundle querySkus = new Bundle();
            querySkus.putStringArrayList("ITEM_ID_LIST", new ArrayList<String>(java.util.Arrays.asList(skus)));
            Log.d("LIGHTNING", "doInBackground " + querySkus.toString());
            Bundle retval = null;

            try {
                retval = mService.getSkuDetails(3, Lightning.activity.getPackageName(), "inapp", querySkus);
            } catch (android.os.RemoteException e) {
                retval = null;
            }

            return retval;
        }

        protected native void nativeOnPostExecute(String[] skus);

        @Override
        protected void onPostExecute(Bundle skuDetails) {
            Log.d("LIGHTNING", "onPostExecute");

            if (skuDetails != null && skuDetails.getInt("RESPONSE_CODE") == 0) {
                Log.d("LIGHTNING", "skuDetails " + skuDetails.toString());

                ArrayList<String> responseList = skuDetails.getStringArrayList("DETAILS_LIST");
                Log.d("LIGHTNING", "resp list " + (new Integer(responseList.size())).toString());

                if (responseList.size() > 0) {
                    ArrayList<String> skus = new ArrayList();

                    for (String thisResponse : responseList) {
                        try {
                            JSONObject object = new JSONObject(thisResponse);
                            skus.add(object.getString("productId"));
                            skus.add(object.getString("price"));
                        } catch (org.json.JSONException e) {
                        }
                    }

                    String[] skusAr = new String[skus.size()];
                    nativeOnPostExecute(skus.toArray(skusAr));
                }
            }
        }
    }
}
