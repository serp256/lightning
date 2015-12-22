package ru.redspell.lightning.payments;

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
import org.json.JSONObject;
import org.json.JSONException;

public class Openiab implements Payments.IPayments {
  final int RC_REQUEST = 10001;
  private OpenIabHelper helper = null;
  private Queue<Runnable> pendingQueue = new LinkedList<Runnable>();
  private boolean setupDone = false;
  private boolean setupFailed = false;

	
  private class PurchaseCommand implements Runnable {
    private String sku;

    public PurchaseCommand(String sku) {
      this.sku = sku;
    }

    public void run() {
      Log.d("LIGHTNING", "Purchase command with sku " + sku);

      if (helper == null) return;

      String payload = "";
      IabHelper.OnIabPurchaseFinishedListener listener = new IabHelper.OnIabPurchaseFinishedListener() {
        public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
          if (result.isSuccess()) {
            Payments.purchaseSuccess(sku, purchase, false);
          } else {
            Payments.purchaseFail(sku, result.getMessage());
          }
        }
      };

      helper.launchPurchaseFlow(NativeActivity.instance, sku, RC_REQUEST, listener, payload);
    }

    public String getSku() {
      return sku;
    }
  }

  private class ConsumeCommand implements Runnable {
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

  private class InventoryCommand implements Runnable {
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
            Log.d("LIGHTNING", "onQueryInventoryFinished " + result.isSuccess());
          if (result.isSuccess()) {
            if (detailsForSkus != null) {
              for (int i = 0; i < detailsForSkus.length; i++) {
                SkuDetails details = inventory.getSkuDetails(detailsForSkus[i]);
                if (details == null) continue;
                String price = details.getPrice();
                if (price == null) continue;

                Log.d("LIGHTNING", "purchaseRegister");
                Payments.purchaseRegister(detailsForSkus[i], price);

                Log.d("LIGHTNING", "details " + details);

								String rawJson = details.getJson ();
								if (rawJson == null) {
									String dollar = "$";
									if (price.startsWith(dollar)) {
										try {
											double d_amount = Double.parseDouble (price.substring(1));
											Payments.purchaseDetailsRegister(detailsForSkus[i], new Payments.LightDetails ("USD", d_amount));
										}
										catch (java.lang.RuntimeException exc) {
											Log.d("LIGHTNING", "JSON exc" + (exc.toString ()));
									  }
									}
								}
								else {
									try {
										JSONObject json = new JSONObject (details.getJson());
										Log.d("LIGHTNING", "JSON " + json);
										long amount = json.getLong ("price_amount_micros");
										String currency = json.getString ("price_currency_code");
										double d_amount = amount / 1000000.;
										Log.d("LIGHTNING", "java amount " + amount + " " + d_amount);
										Payments.purchaseDetailsRegister(detailsForSkus[i], new Payments.LightDetails (currency, d_amount));
									}
									catch (JSONException exc) {
										Log.d("LIGHTNING", "JSON exc" + (exc.toString ()));
									}
								}
              }
            } else if (forOwnedPurchases) {
              Iterator<Purchase> iter = inventory.getAllPurchases().iterator();
              while (iter.hasNext()) {
                Purchase purchase = iter.next();
                Payments.purchaseSuccess(purchase.getSku(), purchase, true);
              }
            }
          }
        }
      };

      helper.queryInventoryAsync(detailsForSkus != null, detailsForSkus != null ? Arrays.asList(detailsForSkus) : null, listener);
    }
  }

  private void runPending() {
    Runnable pending;

    while ((pending = pendingQueue.poll()) != null) {
      pending.run();
    }
  }

  private void failPendings() {
    Runnable pending;

    while ((pending = pendingQueue.poll()) != null) {
      if (pending instanceof PurchaseCommand) {
        PurchaseCommand purchase = (PurchaseCommand)pending;
        Payments.purchaseFail(purchase.getSku(), "pending purchase failed cause setup failed");
      }
    }
  }

  public void init(String[] _skus, String marketType) {
     try {
         final String[] skus = _skus;
         Log.d("LIGHTNING", "init call " + marketType + " isSamsungTestMode " + org.onepf.oms.appstore.SamsungApps.isSamsungTestMode);
         if (helper != null) return;

         Log.d("LIGHTNING", "continue");
				 Logger.setLoggable(true);

         setupFailed = false;
         ArrayList<String> prefStores = new ArrayList<String>(1);
         prefStores.add(marketType);
				 String[] prefStoresArr = prefStores.toArray (new String[prefStores.size()]);

         //to be able use samsung store at least one sku mapping needed. it is absolutely fake needed only to workaround openiab strange behaviour
         OpenIabHelper.mapSku("ru.redspell.lightning.fameSamsungPurchase", OpenIabHelper.NAME_SAMSUNG, "100000104912/ru.redspell.lightning.fameSamsungPurchase");
         OpenIabHelper.Options.Builder builder = new OpenIabHelper.Options.Builder()
             .addPreferredStoreName(prefStoresArr)
						 .setStoreSearchStrategy(OpenIabHelper.Options.SEARCH_STRATEGY_INSTALLER_THEN_BEST_FIT)
             .setVerifyMode(OpenIabHelper.Options.VERIFY_SKIP);
         OpenIabHelper.Options opts = opts = builder.build();
         OpenIabHelper.enableDebugLogging(true);

         helper = new OpenIabHelper(NativeActivity.instance, opts);
         NativeActivity.instance.addUiLifecycleHelper(new IUiLifecycleHelper() {
             public void onCreate(Bundle savedInstanceState) {}
             public void onResume() {}
             public void onActivityResult(int requestCode, int resultCode, Intent data) {
                 Log.d("LIGHTNING", "openiab onActivityResult " + requestCode + " resultCode " + resultCode + " data " + data);
                 helper.handleActivityResult(requestCode, resultCode, data);
             }
             public void onSaveInstanceState(Bundle outState) {}
             public void onPause() {}
             public void onStop() {}
             public void onDestroy() {}
						 public void onStart() {}
         });

         helper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
                     public void onIabSetupFinished(IabResult result) {
                         if (!result.isSuccess()) {
                             failPendings();
                             setupFailed = true;
                             return;
                         }

                         setupDone = true;
                         runPending();
                         request(new InventoryCommand(skus));
                     }
                 });
     } catch (Exception e ) {}

  }

  private void request(Runnable request) {
    if (setupDone) {
        request.run();
    } else if (setupFailed) {
        if (request instanceof PurchaseCommand) {
          PurchaseCommand purchase = (PurchaseCommand)request;
          Payments.purchaseFail(purchase.getSku(), "purchase failed cause setup failed");
        }
    } else {
        pendingQueue.add(request);
    }
  }

  public void purchase(String sku) {
    request(new PurchaseCommand(sku));
  }

  public void consume(Object purchase) {
    request(new ConsumeCommand((Purchase)purchase));
  }

  public void inventory() {
    request(new InventoryCommand());
  }

  public String getOriginalJson(Object purchase) {
      return ((Purchase)purchase).getOriginalJson();
  }

  public String getToken(Object purchase) {
      return ((Purchase)purchase).getToken();
  }

  public String getSignature(Object purchase) {
      return ((Purchase)purchase).getSignature();
  }
}
