/*
 * Copyright 2012-2014 One Platform Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package ru.redspell.lightning.payments.openiab.appstore;

import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import android.content.pm.ResolveInfo;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.onepf.oms.Appstore;
import org.onepf.oms.AppstoreInAppBillingService;
import org.onepf.oms.DefaultAppstore;
import org.onepf.oms.OpenIabHelper;
import org.onepf.oms.util.CollectionUtils;
import org.onepf.oms.util.Logger;
import org.onepf.oms.util.Utils;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.IBinder;
import android.os.RemoteException;

import com.android.vending.billing.IInAppBillingService;




public class BazaarAppStore extends DefaultAppstore {

    public static final String NAME_BAZAAR = "com.farsitel.bazaar";

    public static final String BAZAAR_INSTALLER = "com.farsitel.bazaar";
    
    public static final String VENDING_ACTION = "ir.cafebazaar.pardakht.InAppBillingService.BIND";
    
    private Context context;
    
    private BazaarIabHelper mBillingService;
    
    private String publicKey;
    
    
    @Nullable
    // undefined until isBillingAvailable() is called
    private volatile Boolean billingAvailable = null; 

    
    // isDebugMode = true |-> always returns app installed via Google Play
    private final boolean isDebugMode = false;

    public BazaarAppStore(Context context, String publicKey) {
        this.context = context;
        this.publicKey = publicKey;
    }

    @Override
    public boolean isPackageInstaller(String packageName) {
        return Utils.isPackageInstaller(context, BazaarAppStore.BAZAAR_INSTALLER);
    }

    /**
     * Assume Android app is published in Google Play in any case.
     * <ul><li>
     * - check Bazaar package is installed<li>
     * - check Bazaar Vending service is available<li>
     * - check Bazaar Vending supports v3 items TYPE_IN-APP
     * </ul>
     *
     * @return true if Bazaar is installed in the system
     */
    @Override
    public boolean isBillingAvailable(final String packageName) {
        
        Logger.d("isBillingAvailable() packageName: ", packageName);
        
        if (billingAvailable != null) {
            return billingAvailable; // return previosly checked result
        }

        if (Utils.uiThread()) {
            throw new IllegalStateException("Must no be called from UI thread.");
        }

        if (!packageExists(context, BazaarAppStore.BAZAAR_INSTALLER)) {
            Logger.d("isBillingAvailable() Google Play is not available.");
            return false;
        }

        final Intent intent = new Intent(BazaarAppStore.VENDING_ACTION);

        intent.setPackage(BazaarAppStore.BAZAAR_INSTALLER);

        final List<ResolveInfo> infoList = context.getPackageManager().queryIntentServices(intent, 0);

        if (CollectionUtils.isEmpty(infoList)) {
            Logger.e("isBillingAvailable() billing service is not available, even though Google Play application seems to be installed.");
            return false;
        }

        final CountDownLatch latch = new CountDownLatch(1);
        final boolean[] result = new boolean[1];
        final ServiceConnection serviceConnection = new ServiceConnection() {
            public void onServiceConnected(ComponentName name, IBinder service) {
                final IInAppBillingService mService = IInAppBillingService.Stub.asInterface(service);
                try {
                    final int response = mService.isBillingSupported(3, packageName, BazaarIabHelper.ITEM_TYPE_INAPP);
                    result[0] = response == BazaarIabHelper.BILLING_RESPONSE_RESULT_OK;
                } catch (RemoteException e) {
                    result[0] = false;
                    Logger.e("isBillingAvailable() RemoteException while setting up in-app billing", e);
                } finally {
                    latch.countDown();
                    context.unbindService(this);
                }
                Logger.d("isBillingAvailable() Google Play result: ", result[0]);
            }

            public void onServiceDisconnected(ComponentName name) {/*do nothing*/}
        };
        
        if (context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)) {
            try {
                latch.await();
            } catch (InterruptedException e) {
                Logger.e("isBillingAvailable() InterruptedException while setting up in-app billing", e);
            }
        } else {
            result[0] = false;
            Logger.e("isBillingAvailable() billing is not supported. Initialization error.");
        }
        return (billingAvailable = result[0]);
    }

    @Override
    public int getPackageVersion(String packageName) {
        return Appstore.PACKAGE_VERSION_UNDEFINED;
    }


    @Override
    public AppstoreInAppBillingService getInAppBillingService() {
        if (mBillingService == null) {
            mBillingService = new BazaarIabHelper(context, publicKey, this);
        }
        return mBillingService;
    }

    @Override
    public String getAppstoreName() {
        return BazaarAppStore.NAME_BAZAAR;
    }

    private boolean packageExists(@NotNull Context context, String packageName) {
        try {
            context.getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            Logger.d(packageName, " package was not found.");
            return false;
        }
    }

}
