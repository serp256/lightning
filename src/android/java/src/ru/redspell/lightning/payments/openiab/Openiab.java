package ru.redspell.lightning.payments.openiab;

import android.content.Intent;
import android.os.Bundle;

import ru.redspell.lightning.NativeActivity;
import ru.redspell.lightning.IUiLifecycleHelper;
import ru.redspell.lightning.utils.Log;

import org.onepf.oms.OpenIabHelper;
import org.onepf.oms.appstore.googleUtils.IabHelper;
import org.onepf.oms.appstore.googleUtils.IabResult;
import org.onepf.oms.appstore.googleUtils.Purchase;
import org.onepf.oms.appstore.googleUtils.Inventory;
import org.onepf.oms.appstore.googleUtils.SkuDetails;
import org.onepf.oms.util.Logger;

import java.util.LinkedList;
import java.util.Arrays;
import java.util.Queue;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Iterator;

public class Openiab {
  static final int RC_REQUEST = 10001;
  private static OpenIabHelper helper = null;
  private static Queue<Runnable> pendingQueue = new LinkedList<Runnable>();
  private static boolean setupDone = false;
  private static boolean setupFailed = false;

  public static native void purchaseSuccess(String sku, Purchase purchase, boolean restored);
  public static native void purchaseFail(String sku, String reason);
  public static native void purchaseRegister(String sku, String price);

  private static class PurchaseCommand implements Runnable {
    private String sku;

    public PurchaseCommand(String sku) {
      this.sku = sku;
    }

    public void run() {
      if (helper == null) return;

      String payload = "";
      IabHelper.OnIabPurchaseFinishedListener listener = new IabHelper.OnIabPurchaseFinishedListener() {
        public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
          if (result.isSuccess()) {
            Openiab.purchaseSuccess(sku, purchase, false);
          } else {
            Openiab.purchaseFail(sku, result.getMessage());
          }
        }
      };

      helper.launchPurchaseFlow(NativeActivity.instance, sku, RC_REQUEST, listener, payload);
    }

    public String getSku() {
      return sku;
    }
  }

  private static class ConsumeCommand implements Runnable {
    private Purchase purchase;

    public ConsumeCommand(Purchase purchase) {
      this.purchase = purchase;
    }

    public void run() {
      if (helper == null) return;
      helper.consumeAsync(purchase, new IabHelper.OnConsumeFinishedListener() {
         public void onConsumeFinished(Purchase purchase, IabResult result) {}
      });
    }
  }

  private static class InventoryCommand implements Runnable {
    private String[] detailsForSkus = null;
    private boolean forOwnedPurchases = false;

    public InventoryCommand(String[] detailsForSkus) {
      this.detailsForSkus = detailsForSkus;
    }

    public InventoryCommand() {
      forOwnedPurchases = true;
    }

    public void run() {
      if (helper == null) return;

      IabHelper.QueryInventoryFinishedListener listener = new IabHelper.QueryInventoryFinishedListener() {
        public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
          if (result.isSuccess()) {
            if (detailsForSkus != null) {
              for (int i = 0; i < detailsForSkus.length; i++) {
                SkuDetails details = inventory.getSkuDetails(detailsForSkus[i]);
                if (details == null) continue;
                String price = details.getPrice();
                if (price == null) continue;

                Openiab.purchaseRegister(detailsForSkus[i], price);
              }
            } else if (forOwnedPurchases) {
              Iterator<Purchase> iter = inventory.getAllPurchases().iterator();
              while (iter.hasNext()) {
                Purchase purchase = iter.next();
                Openiab.purchaseSuccess(purchase.getSku(), purchase, true);
              }
            }
          }
        }
      };

      helper.queryInventoryAsync(detailsForSkus != null, detailsForSkus != null ? Arrays.asList(detailsForSkus) : null, listener);
    }
  }

  private static void runPending() {
    Runnable pending;

    while ((pending = pendingQueue.poll()) != null) {
      pending.run();
    }
  }

  private static void failPendings() {
    Runnable pending;

    while ((pending = pendingQueue.poll()) != null) {
      if (pending instanceof PurchaseCommand) {
        PurchaseCommand purchase = (PurchaseCommand)pending;
        purchaseFail(purchase.getSku(), "pending purchase failed cause setup failed");
      }
    }
  }

  public static void init(final String[] skus, String marketType) {
    if (helper != null) return;

    setupFailed = false;
    ArrayList<String> prefStores = new ArrayList<String>(1);
    prefStores.add(marketType);

    OpenIabHelper.Options.Builder builder = new OpenIabHelper.Options.Builder()
        .addPreferredStoreName(prefStores)
        .setVerifyMode(OpenIabHelper.Options.VERIFY_SKIP);
/*        .addStoreKey(OpenIabHelper.NAME_YANDEX, "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1Ktx/LPWTaZJeHsIp/UCBok0Ji1vdUVd0VP2vrl+Mb8B1z8E1uNUpotuZRiQyAnvJjyZTMQxKbPJMwFQy5Tuxlr1TTXqy/8ZuSOy+dzhwuYqJ0soK5rNY1INu1pvVWbr3IEQ7npq6JKGc5sR0hYtOyIv2Ftzj3fCzwp7tcjEKBLKTFHPKGEiWpfOLF1KYOAhIOgAJ47vrif0sI4UDunwU45ZVBRz5OQu55xxNLgZVoVs9L8j+i52Qg0vrVoJNJ97WNPs5WLxKFzBncA1K7tS1GdToxDMU3ruUu7nydpjtXyjKthMUunRVu2UNFCs1WrcCmuOWiNSoXuxDd2ww5kiNwIDAQAB")
        .setVerifyMode(OpenIabHelper.Options.VERIFY_EVERYTHING);*/
    OpenIabHelper.Options opts = opts = builder.build();
    OpenIabHelper.enableDebugLogging(true);

    helper = new OpenIabHelper(NativeActivity.instance, opts);
    helper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
                public void onIabSetupFinished(IabResult result) {
                    if (!result.isSuccess()) {
                        failPendings();
                        setupFailed = true;
                        return;
                    }

                    NativeActivity.instance.addUiLifecycleHelper(new IUiLifecycleHelper() {
                      public void onCreate(Bundle savedInstanceState) {}
                      public void onResume() {}
                      public void onActivityResult(int requestCode, int resultCode, Intent data) {
                        helper.handleActivityResult(requestCode, resultCode, data);
                      }
                      public void onSaveInstanceState(Bundle outState) {}
                      public void onPause() {}
                      public void onStop() {}
                      public void onDestroy() {}
                    });

                    setupDone = true;
                    runPending();
                    request(new InventoryCommand(skus));
                }
            });
  }

  private static void request(Runnable request) {
    if (setupDone) {
        request.run();
    } else if (setupFailed) {
        if (request instanceof PurchaseCommand) {
          PurchaseCommand purchase = (PurchaseCommand)request;
          purchaseFail(purchase.getSku(), "purchase failed cause setup failed");
        }
    } else {
        pendingQueue.add(request);
    }
  }

  public static void purchase(String sku) {
    request(new PurchaseCommand(sku));
  }

  public static void consume(Purchase purchase) {
    request(new ConsumeCommand(purchase));
  }

  public static void inventory() {
    request(new InventoryCommand());
  }
}
