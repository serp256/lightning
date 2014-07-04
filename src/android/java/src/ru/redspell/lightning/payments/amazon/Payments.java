package ru.redspell.lightning.payments.amazon;

import com.amazon.inapp.purchasing.BasePurchasingObserver;
import com.amazon.inapp.purchasing.PurchaseResponse;
import com.amazon.inapp.purchasing.PurchaseResponse.PurchaseRequestStatus;
import com.amazon.inapp.purchasing.PurchaseUpdatesResponse;
import com.amazon.inapp.purchasing.PurchaseUpdatesResponse.PurchaseUpdatesRequestStatus;
import com.amazon.inapp.purchasing.PurchasingManager;
import com.amazon.inapp.purchasing.Receipt;

import ru.redspell.lightning.payments.PaymentsCallbacks;
import ru.redspell.lightning.utils.Log;

import android.content.Context;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

public class Payments extends BasePurchasingObserver {
    private HashMap<String,String> reqIdSkuMap = new HashMap<String,String>();

    public Payments(Context context) {
        super(context);
    }

    public void init(String[] skus) {
        PurchasingManager.registerObserver(this);
    }

    public void purchase(String sku) {
        reqIdSkuMap.put(PurchasingManager.initiatePurchaseRequest(sku), sku);
    }

    public void comsumePurchase(String purchaseToken) {
        //no need to do here anything
    }

    public void restorePurchases() {
        PurchasingManager.initiatePurchaseUpdatesRequest(com.amazon.inapp.purchasing.Offset.BEGINNING);
    }

    public void onPurchaseResponse(PurchaseResponse purchaseResponse) {
        Log.d("LIGHTNING", "onPurchaseResponse call");

        String requestId = purchaseResponse.getRequestId();
        if (reqIdSkuMap.containsKey(requestId)) {
            PurchaseRequestStatus status = purchaseResponse.getPurchaseRequestStatus();

            if (status == PurchaseRequestStatus.SUCCESSFUL) {
                Receipt receipt = purchaseResponse.getReceipt();
                PaymentsCallbacks.success(receipt.getSku(), receipt.getPurchaseToken(), receipt.getPurchaseToken(), purchaseResponse.getUserId(), false);
            } else {
                PaymentsCallbacks.fail(reqIdSkuMap.get(requestId), "purchase request status " + status);
            }

            reqIdSkuMap.remove(requestId);            
        } else {
            PaymentsCallbacks.fail("none", "unknown request id");
        }
    }

    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse purchaseUpdatesResponse) {
        Log.d("LIGHTNING", "onPurchaseUpdatesResponse call");

        PurchaseUpdatesRequestStatus status = purchaseUpdatesResponse.getPurchaseUpdatesRequestStatus();

        if (status == PurchaseUpdatesRequestStatus.SUCCESSFUL) {
            Set<Receipt> receipts = purchaseUpdatesResponse.getReceipts();
            Iterator<Receipt> iterator = receipts.iterator();

            while (iterator.hasNext()) {
                Receipt receipt = iterator.next();
                PaymentsCallbacks.success(receipt.getSku(), receipt.getPurchaseToken(), receipt.getPurchaseToken(), purchaseUpdatesResponse.getUserId(), true);
            }

            if (purchaseUpdatesResponse.isMore()) {
                PurchasingManager.initiatePurchaseUpdatesRequest(purchaseUpdatesResponse.getOffset());
            }
        } else {
            PaymentsCallbacks.fail("none", "purchase request status " + status);
        }
    }

    public void getSkuDetails(String[] skus) {}
}
