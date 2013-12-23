package ru.redspell.lightning.payments.amazon;

import com.amazon.inapp.purchasing.BasePurchasingObserver;
import com.amazon.inapp.purchasing.PurchaseResponse;
import com.amazon.inapp.purchasing.PurchaseResponse.PurchaseRequestStatus;
import com.amazon.inapp.purchasing.PurchaseUpdatesResponse;
import com.amazon.inapp.purchasing.PurchaseUpdatesResponse.PurchaseUpdatesRequestStatus;
import com.amazon.inapp.purchasing.PurchasingManager;
import com.amazon.inapp.purchasing.Receipt;

import ru.redspell.lightning.payments.ILightPayments;
import ru.redspell.lightning.payments.LightPaymentsCamlCallbacks;
import ru.redspell.lightning.utils.Log;

import android.content.Context;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

public class LightAmazonPayments extends BasePurchasingObserver implements ILightPayments {
    private HashMap<String,String> reqIdSkuMap = new HashMap<String,String>();

    public LightAmazonPayments(Context context) {
        super(context);
    }

    @Override
    public void init(String[] skus) {
        PurchasingManager.registerObserver(this);
    }

    @Override
    public void purchase(String sku) {
        reqIdSkuMap.put(PurchasingManager.initiatePurchaseRequest(sku), sku);
    }

    @Override
    public void comsumePurchase(String purchaseToken) {
        //no need to do here anything
    }

    @Override
    public void restorePurchases() {
        PurchasingManager.initiatePurchaseUpdatesRequest(com.amazon.inapp.purchasing.Offset.BEGINNING);
    }

    @Override
    public void onPurchaseResponse(PurchaseResponse purchaseResponse) {
        Log.d("LIGHTNING", "onPurchaseResponse call");

        String requestId = purchaseResponse.getRequestId();
        if (reqIdSkuMap.containsKey(requestId)) {
            PurchaseRequestStatus status = purchaseResponse.getPurchaseRequestStatus();

            if (status == PurchaseRequestStatus.SUCCESSFUL) {
                Receipt receipt = purchaseResponse.getReceipt();
                LightPaymentsCamlCallbacks.success(receipt.getSku(), receipt.getPurchaseToken(), receipt.getPurchaseToken(), purchaseResponse.getUserId(), false);
            } else {
                LightPaymentsCamlCallbacks.fail(reqIdSkuMap.get(requestId), "purchase request status " + status);
            }

            reqIdSkuMap.remove(requestId);            
        } else {
            LightPaymentsCamlCallbacks.fail("none", "unknown request id");
        }
    }

    @Override
    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse purchaseUpdatesResponse) {
        Log.d("LIGHTNING", "onPurchaseUpdatesResponse call");

        PurchaseUpdatesRequestStatus status = purchaseUpdatesResponse.getPurchaseUpdatesRequestStatus();

        if (status == PurchaseUpdatesRequestStatus.SUCCESSFUL) {
            Set<Receipt> receipts = purchaseUpdatesResponse.getReceipts();
            Iterator<Receipt> iterator = receipts.iterator();

            while (iterator.hasNext()) {
                Receipt receipt = iterator.next();
                LightPaymentsCamlCallbacks.success(receipt.getSku(), receipt.getPurchaseToken(), receipt.getPurchaseToken(), purchaseUpdatesResponse.getUserId(), true);
            }

            if (purchaseUpdatesResponse.isMore()) {
                PurchasingManager.initiatePurchaseUpdatesRequest(purchaseUpdatesResponse.getOffset());
            }
        } else {
            LightPaymentsCamlCallbacks.fail("none", "purchase request status " + status);
        }
    }

    public void getSkuDetails(String[] skus) {}
}
