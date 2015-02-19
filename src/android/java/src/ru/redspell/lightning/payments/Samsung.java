package ru.redspell.lightning.payments;

import com.sec.android.iap.lib.helper.SamsungIapHelper;
import com.sec.android.iap.lib.listener.OnPaymentListener;
import com.sec.android.iap.lib.listener.OnGetItemListener;
import com.sec.android.iap.lib.vo.PurchaseVo;
import com.sec.android.iap.lib.vo.ErrorVo;
import com.sec.android.iap.lib.vo.ItemVo;

import ru.redspell.lightning.Lightning;
import ru.redspell.lightning.utils.Log;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;

public class Samsung implements Payments.IPayments {
    private SamsungIapHelper helper;
    private int mode;

    private class PaymentListener implements OnPaymentListener {
        private String sku;

        public PaymentListener(String sku) {
            this.sku = sku;
        }

        public void onPayment(ErrorVo err, PurchaseVo purchase) {
            if (err.getErrorCode() == SamsungIapHelper.IAP_ERROR_NONE) {
                Log.d("LIGHTNING", "SUCCESS " + purchase.dump());
                Payments.purchaseSuccess(sku, (Object)purchase, false);
            } else {
                Log.d("LIGHTNING", "ERROR " + err.dump());
                Payments.purchaseFail(sku, err.getErrorString());
            }
        }
    }



    private class GetItemListener implements OnGetItemListener {
        private String[] skus;
        private String groupId;

        public GetItemListener(String groupId, String[] skus) {
            this.skus = skus;
            this.groupId = groupId;
        }

        public void onGetItem(ErrorVo err, ArrayList<ItemVo> items) {
            Log.d("LIGHTNING", "onGetItem callback");

            if (err.getErrorCode() == SamsungIapHelper.IAP_ERROR_NONE) {
                Log.d("LIGHTNING", "no error");

                Iterator<ItemVo> iterator = items.iterator();
                Arrays.sort(skus, String.CASE_INSENSITIVE_ORDER);

                while (iterator.hasNext()) {
                    ItemVo item = iterator.next();
                    Log.d("LIGHTNING", "checking " + item.getItemId());

                    if (Arrays.binarySearch(skus, groupId + "/" + item.getItemId(), String.CASE_INSENSITIVE_ORDER) >= 0) {
                        Log.d("LIGHTNING", "needed, registering, price " + item.getItemPriceString());
                        Payments.purchaseRegister(item.getItemId(), item.getItemPriceString());
                    }
                }
            }
        }
    }

    public Samsung(boolean devMode) {
        mode = devMode ? SamsungIapHelper.IAP_MODE_TEST_SUCCESS : SamsungIapHelper.IAP_MODE_COMMERCIAL;
        helper = SamsungIapHelper.getInstance(Lightning.activity, mode);
    }

    public void init(String[] skus, String marketType) {
        HashSet groups = new HashSet();

        for (int i = 0; i < skus.length; i++) {
            String[] parts = skus[i].split("/");
            groups.add(parts[0]);
        }

        Iterator<String> iterator = groups.iterator();
        while (iterator.hasNext()) {
            String groupId = iterator.next();
            Log.d("LIGHTNING", "requesting list for group " + groupId);
            helper.getItemList(groupId, 1, 100, "10", mode, new GetItemListener(groupId, skus));
        }
    }

    public void purchase(String sku) {
        String[] parts = sku.split("/");
        helper.startPayment(parts[0], parts[1], true, new PaymentListener(sku));
    }

    public void consume(Object purchase) {
    }

    public void inventory() {
    }

    public String getOriginalJson(Object purchase) {
        return "";
    }

    public String getToken(Object purchase) {
        return "";
    }

    public String getSignature(Object purchase) {
        return "";
    }
}
