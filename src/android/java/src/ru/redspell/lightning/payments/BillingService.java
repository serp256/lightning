package ru.redspell.lightning.payments;

import com.android.vending.billing.IMarketBillingService;
import android.app.Activity;

import ru.redspell.lightning.payments.Consts.PurchaseState;
import ru.redspell.lightning.payments.Consts.ResponseCode;
import ru.redspell.lightning.payments.Security.VerifiedPurchase;

import android.app.PendingIntent;
import android.app.Service;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import ru.redspell.lightning.utils.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.lang.Thread;
import android.os.Process;
import ru.redspell.lightning.LightView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class BillingService extends Service implements ServiceConnection {
    private static final String TAG = "LIGHTNING";

    private static IMarketBillingService mService;

    private static LinkedList<BillingRequest> mPendingRequests = new LinkedList<BillingRequest>();

    private static HashMap<Long, BillingRequest> mSentRequests =
        new HashMap<Long, BillingRequest>();

    abstract class BillingRequest {
        private final int mStartId;
        protected long mRequestId;

        public BillingRequest(int startId) {
            mStartId = startId;
        }

        public int getStartId() {
            return mStartId;
        }

        public boolean runRequest() {
            if (runIfConnected()) {
                return true;
            }

            if (bindToMarketBillingService()) {
                // Add a pending request to run when the service is connected.
                mPendingRequests.add(this);
                return true;
            }
            return false;
        }

        public boolean runIfConnected() {
            if (Consts.DEBUG) {
                Log.d(TAG, getClass().getSimpleName());
            }
            if (mService != null) {
                try {
                    mRequestId = run();
                    if (Consts.DEBUG) {
                        Log.d(TAG, "request id: " + mRequestId);
                    }
                    if (mRequestId >= 0) {
                        mSentRequests.put(mRequestId, this);
                    }
                    return true;
                } catch (RemoteException e) {
                    onRemoteException(e);
                }
            }
            return false;
        }

        protected void onRemoteException(RemoteException e) {
            Log.w(TAG, "remote billing service crashed");
            mService = null;
        }

        abstract protected long run() throws RemoteException;

        protected void responseCodeReceived(ResponseCode responseCode) {
        }

        protected Bundle makeRequestBundle(String method) {
            Bundle request = new Bundle();
            request.putString(Consts.BILLING_REQUEST_METHOD, method);
            request.putInt(Consts.BILLING_REQUEST_API_VERSION, 1);
            request.putString(Consts.BILLING_REQUEST_PACKAGE_NAME, getPackageName());
            return request;
        }

        protected void logResponseCode(String method, Bundle response) {
            ResponseCode responseCode = ResponseCode.valueOf(
                    response.getInt(Consts.BILLING_RESPONSE_RESPONSE_CODE));
            if (Consts.DEBUG) {
                Log.e(TAG, method + " received " + responseCode.toString());
            }
        }
    }

    class CheckBillingSupported extends BillingRequest {
        public String mProductType = null;

        @Deprecated
        public CheckBillingSupported() {
            super(-1);
        }

        public CheckBillingSupported(String itemType) {
            super(-1);
            mProductType = itemType;
        }
        
        @Override
        protected long run() throws RemoteException {
            Bundle request = makeRequestBundle("CHECK_BILLING_SUPPORTED");
            if (mProductType != null) {
                request.putString(Consts.BILLING_REQUEST_ITEM_TYPE, mProductType);
            }
            Bundle response = mService.sendBillingRequest(request);
            int responseCode = response.getInt(Consts.BILLING_RESPONSE_RESPONSE_CODE);
            if (Consts.DEBUG) {
                Log.i(TAG, "CheckBillingSupported response code: " +
                        ResponseCode.valueOf(responseCode));
            }
            boolean billingSupported = (responseCode == ResponseCode.RESULT_OK.ordinal());
            ResponseHandler.checkBillingSupportedResponse(billingSupported, mProductType);
            return Consts.BILLING_RESPONSE_INVALID_REQUEST_ID;
        }
    }

    class RequestPurchase extends BillingRequest {
        public final String mProductId;
        public final String mDeveloperPayload;
        public final String mProductType;

        @Deprecated
        public RequestPurchase(String itemId) {
            this(itemId, null, null);
        }

        @Deprecated
        public RequestPurchase(String itemId, String developerPayload) {
            this(itemId, null, developerPayload);
        }

        public RequestPurchase(String itemId, String itemType, String developerPayload) {
            super(-1);
            mProductId = itemId;
            mDeveloperPayload = developerPayload;
            mProductType = itemType;
        }

        @Override
        protected long run() throws RemoteException {
            Log.d("LIGHTNING", "request purchase (RequestPurchase.run) " + mProductId + ' ' + mProductType);

            Bundle request = makeRequestBundle("REQUEST_PURCHASE");
            request.putString(Consts.BILLING_REQUEST_ITEM_ID, mProductId);
            request.putString(Consts.BILLING_REQUEST_ITEM_TYPE, mProductType);
            // Note that the developer payload is optional.
            if (mDeveloperPayload != null) {
                request.putString(Consts.BILLING_REQUEST_DEVELOPER_PAYLOAD, mDeveloperPayload);
            }
            Bundle response = mService.sendBillingRequest(request);
            PendingIntent pendingIntent
                    = response.getParcelable(Consts.BILLING_RESPONSE_PURCHASE_INTENT);
            if (pendingIntent == null) {
                Log.e(TAG, "Error with requestPurchase");
                return Consts.BILLING_RESPONSE_INVALID_REQUEST_ID;
            }

            Intent intent = new Intent();
            //ResponseHandler.buyPageIntentResponse(pendingIntent, intent);

            Activity act = (Activity) getBaseContext();

            if (act == null) {
                Log.e(TAG, "ResponseHandler activity is not initialized");
                return Consts.BILLING_RESPONSE_INVALID_REQUEST_ID;
            }

            try {
                act.startIntentSender(pendingIntent.getIntentSender(), intent, 0, 0, 0);
            } catch (Exception e) {
                Log.e(TAG, "error starting activity", e);
            }            

            return response.getLong(Consts.BILLING_RESPONSE_REQUEST_ID,
                    Consts.BILLING_RESPONSE_INVALID_REQUEST_ID);
        }

        @Override
        protected void responseCodeReceived(ResponseCode responseCode) {
            Log.d("LIGHTNING", "request purchase response code received (RequestPurchase.responseCodeReceived): " + responseCode);

            String mes = null;

            switch (responseCode) {
                case RESULT_USER_CANCELED:
                    mes = "User cancel operation";
                    break;

                case RESULT_SERVICE_UNAVAILABLE:
                    mes = "Some network problems";
                    break;

                case RESULT_BILLING_UNAVAILABLE:
                    mes = "Payments are not available";
                    break;

                case RESULT_ITEM_UNAVAILABLE:
                    mes = "Wrong product id";
                    break;

                case RESULT_DEVELOPER_ERROR:
                    mes = "Develper error";
                    break;

                case RESULT_ERROR:
                    mes = "Server error";
                    break;
            }

            Log.d("LIGHTNING", "request purchase response code received mes: " + (mes != null ? mes : "null"));

            if (mes != null) {
                final String fmes = mes;

                if (LightView.instance != null) {
                    LightView.instance.queueEvent(new Runnable() {
                        @Override
                        public void run() {
                            invokeCamlPaymentErrorCb(mProductId, fmes);
                        }
                    });
                }
            }
        }
    }

    /**
     * Wrapper class that confirms a list of notifications to the server.
     */
    class ConfirmNotifications extends BillingRequest {
        final String[] mNotifyIds;

        public ConfirmNotifications(int startId, String[] notifyIds) {
            super(startId);
            mNotifyIds = notifyIds;
        }

        @Override
        protected long run() throws RemoteException {
            Log.d(TAG, "confrim notification (ConfirmNotifications.run)");

            Bundle request = makeRequestBundle("CONFIRM_NOTIFICATIONS");
            request.putStringArray(Consts.BILLING_REQUEST_NOTIFY_IDS, mNotifyIds);
            Bundle response = mService.sendBillingRequest(request);
            logResponseCode("confirmNotifications", response);
            return response.getLong(Consts.BILLING_RESPONSE_REQUEST_ID,
                    Consts.BILLING_RESPONSE_INVALID_REQUEST_ID);
        }
    }

    /**
     * Wrapper class that sends a GET_PURCHASE_INFORMATION message to the server.
     */
    class GetPurchaseInformation extends BillingRequest {
        long mNonce;
        final String[] mNotifyIds;

        public GetPurchaseInformation(int startId, String[] notifyIds) {
            super(startId);
            mNotifyIds = notifyIds;
        }

        @Override
        protected long run() throws RemoteException {
            Log.d(TAG, "get purchase information (GetPurchaseInformation.run)");

            mNonce = Security.generateNonce();

            Bundle request = makeRequestBundle("GET_PURCHASE_INFORMATION");
            request.putLong(Consts.BILLING_REQUEST_NONCE, mNonce);
            request.putStringArray(Consts.BILLING_REQUEST_NOTIFY_IDS, mNotifyIds);
            Bundle response = mService.sendBillingRequest(request);
            logResponseCode("getPurchaseInformation", response);
            return response.getLong(Consts.BILLING_RESPONSE_REQUEST_ID,
                    Consts.BILLING_RESPONSE_INVALID_REQUEST_ID);
        }

        @Override
        protected void onRemoteException(RemoteException e) {
            super.onRemoteException(e);
            Security.removeNonce(mNonce);
        }
    }

    /**
     * Wrapper class that sends a RESTORE_TRANSACTIONS message to the server.
     */
/*    class RestoreTransactions extends BillingRequest {
        long mNonce;

        public RestoreTransactions() {
            // This object is never created as a side effect of starting this
            // service so we pass -1 as the startId to indicate that we should
            // not stop this service after executing this request.
            super(-1);
        }

        @Override
        protected long run() throws RemoteException {
            mNonce = Security.generateNonce();

            Bundle request = makeRequestBundle("RESTORE_TRANSACTIONS");
            request.putLong(Consts.BILLING_REQUEST_NONCE, mNonce);
            Bundle response = mService.sendBillingRequest(request);
            logResponseCode("restoreTransactions", response);
            return response.getLong(Consts.BILLING_RESPONSE_REQUEST_ID,
                    Consts.BILLING_RESPONSE_INVALID_REQUEST_ID);
        }

        @Override
        protected void onRemoteException(RemoteException e) {
            super.onRemoteException(e);
            Security.removeNonce(mNonce);
        }

        @Override
        protected void responseCodeReceived(ResponseCode responseCode) {
            ResponseHandler.responseCodeReceived(BillingService.this, this, responseCode);
        }
    }*/

    public void setContext(Context context) {
        attachBaseContext(context);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onStart(Intent intent, int startId) {
        //Log.d(TAG, "onStart call, intent: " + intent);
				if (intent != null) handleCommand(intent, startId);
    }

    public void handleCommand(Intent intent, int startId) {
        Log.d(TAG, "handle command (BillingService.handleCommand), action: " + intent.getAction());

        String action = intent.getAction();

        if (Consts.ACTION_CONFIRM_NOTIFICATION.equals(action)) {
            String[] notifyIds = intent.getStringArrayExtra(Consts.NOTIFICATION_ID);
            confirmNotifications(startId, notifyIds);
        } else if (Consts.ACTION_GET_PURCHASE_INFORMATION.equals(action)) {
            String notifyId = intent.getStringExtra(Consts.NOTIFICATION_ID);
            getPurchaseInformation(startId, new String[] { notifyId });
        } else if (Consts.ACTION_PURCHASE_STATE_CHANGED.equals(action)) {
            String signedData = intent.getStringExtra(Consts.INAPP_SIGNED_DATA);
            String signature = intent.getStringExtra(Consts.INAPP_SIGNATURE);
            purchaseStateChanged(startId, signedData, signature);
        } else if (Consts.ACTION_RESPONSE_CODE.equals(action)) {
            long requestId = intent.getLongExtra(Consts.INAPP_REQUEST_ID, -1);
            int responseCodeIndex = intent.getIntExtra(Consts.INAPP_RESPONSE_CODE,
                    ResponseCode.RESULT_ERROR.ordinal());
            ResponseCode responseCode = ResponseCode.valueOf(responseCodeIndex);
            checkResponseCode(requestId, responseCode);
        }
    }

    private boolean bindToMarketBillingService() {
        try {
            if (Consts.DEBUG) {
                Log.i(TAG, "binding to Market billing service");
            }
            boolean bindResult = bindService(
                    new Intent(Consts.MARKET_BILLING_SERVICE_ACTION),
                    this,  // ServiceConnection.
                    Context.BIND_AUTO_CREATE);

            if (bindResult) {
                return true;
            } else {
                Log.e(TAG, "Could not bind to service.");
            }
        } catch (SecurityException e) {
            Log.e(TAG, "Security exception: " + e);
        }
        return false;
    }

    @Deprecated
    public boolean checkBillingSupported() {
        return new CheckBillingSupported().runRequest();
    }

    public boolean checkBillingSupported(String itemType) {
        return new CheckBillingSupported(itemType).runRequest();
    }

    public boolean requestPurchase(String productId, String itemType, String developerPayload) {
        return new RequestPurchase(productId, itemType, developerPayload).runRequest();
    }

    public boolean requestPurchase(String productId) {
        return requestPurchase(productId, Consts.ITEM_TYPE_INAPP, null);
    }

    private boolean confirmNotifications(int startId, String[] notifyIds) {
        return new ConfirmNotifications(startId, notifyIds).runRequest();
    }

    private boolean getPurchaseInformation(int startId, String[] notifyIds) {
        return new GetPurchaseInformation(startId, notifyIds).runRequest();
    }

    private void purchaseStateChanged(int startId, final String signedData, final String signature) {
        Log.d(TAG, "purchase state changed (BillingService.purchaseStateChanged)");
        Log.d("BILLING_SERVICE", "________________");
        Log.d("BILLING_SERVICE", signedData);
        Log.d("BILLING_SERVICE", signature);

        final String sig = signature;
        ArrayList<Security.VerifiedPurchase> purchases;

        if (Security.hasPubkey()) {
            purchases = Security.verifyPurchase(signedData, signature, false);
            if (purchases == null) {
                Log.d(TAG, "purchases == null");

                if (LightView.instance != null) {
                    LightView.instance.queueEvent(new Runnable() {
                        @Override
                        public void run() {
                            Log.d(TAG, "invoking caml payment error cb from BillingService.purchaseStateChanged (purchases not verified)");
                            invokeCamlPaymentErrorCb("", "error when verifying");
                        }
                    });                    
                }
                
                return;
            }                
        } else {
            if (LightView.instance != null) {
                JSONObject jObject;
                JSONArray jTransactionsArray = null;
                int numTransactions = 0;

                try {
                    jObject = new JSONObject(signedData);
                    jTransactionsArray = jObject.optJSONArray("orders");

                    if (jTransactionsArray != null) {
                        numTransactions = jTransactionsArray.length();
                    }

                    for (int i = 0; i < numTransactions; i++) {
                        JSONObject jElement = jTransactionsArray.getJSONObject(i);
                        PurchaseState purchaseState = PurchaseState.valueOf(jElement.getInt("purchaseState"));

                        Log.d("LIGHTNING", "purchase state: " + jElement.getInt("purchaseState"));
                        /*
                        if (purchaseState == PurchaseState.PURCHASED && !verified && !skip) {
                            continue;
                        }
                        */
                    }

                } catch (JSONException e) {
                    Log.e(TAG, "JSONException");
                    return;
                }

                LightView.instance.queueEvent(new Runnable() {
                    @Override
                    public void run() {
                        invokeCamlPaymentSuccessCb(signedData, "", signature, "");
                    }
                });
            }

            return;
        }

        Log.d(TAG, "purchases len: " + purchases.size());

        //ArrayList<String> notifyList = new ArrayList<String>();

        for (final VerifiedPurchase vp : purchases) {
            Log.d(TAG, "purchases id: " + vp.notificationId);

            if (vp.notificationId != null) {
                Log.d(TAG, "invoking caml payment success callback from from BillingService.purchaseStateChanged");

                if (LightView.instance != null) {
                    LightView.instance.queueEvent(new Runnable() {
                        @Override
                        public void run() {
                            invokeCamlPaymentSuccessCb(vp.productId, vp.notificationId, vp.jobj.toString(), Security.hasPubkey() ? sig : "");
                        }
                    });
                }

                
                //notifyList.add(vp.notificationId);
            }
        }

	/*
        if (!notifyList.isEmpty()) {
            String[] notifyIds = notifyList.toArray(new String[notifyList.size()]);
            confirmNotifications(startId, notifyIds);
        }
	*/
    }

    private void checkResponseCode(long requestId, ResponseCode responseCode) {
        BillingRequest request = mSentRequests.get(requestId);
        if (request != null) {
            request.responseCodeReceived(responseCode);
        }
        mSentRequests.remove(requestId);
    }

    private void runPendingRequests() {
        int maxStartId = -1;
        BillingRequest request;
        while ((request = mPendingRequests.peek()) != null) {
            if (request.runIfConnected()) {
                // Remove the request
                mPendingRequests.remove();

                // Remember the largest startId, which is the most recent
                // request to start this service.
                if (maxStartId < request.getStartId()) {
                    maxStartId = request.getStartId();
                }
            } else {
                // The service crashed, so restart it. Note that this leaves
                // the current request on the queue.
                bindToMarketBillingService();
                return;
            }
        }

        // If we get here then all the requests ran successfully.  If maxStartId
        // is not -1, then one of the requests started the service, so we can
        // stop it now.
        if (maxStartId >= 0) {
            if (Consts.DEBUG) {
                Log.i(TAG, "stopping service, startId: " + maxStartId);
            }
            stopSelf(maxStartId);
        }
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        if (Consts.DEBUG) {
            Log.d(TAG, "Billing service connected");
        }
        mService = IMarketBillingService.Stub.asInterface(service);
        runPendingRequests();
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
        Log.w(TAG, "Billing service disconnected");
        mService = null;
    }

    public void unbind() {
        try {
            unbindService(this);
        } catch (IllegalArgumentException e) {
            // This might happen if the service was disconnected
        }
    }

    public void confirmNotif(String notifId) {
        Log.d(TAG, "BillingService confirmNotif call " + notifId);
        confirmNotifications(-1, new String[] { notifId });
    }

    public native void invokeCamlPaymentSuccessCb(String prodId, String notifId, String signedData, String signature);
    public native void invokeCamlPaymentErrorCb(String prodId, String mes);
}
