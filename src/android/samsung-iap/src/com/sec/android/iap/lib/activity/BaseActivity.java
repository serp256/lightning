package com.sec.android.iap.lib.activity;

import java.util.ArrayList;

import android.app.Activity;
import android.app.Dialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.sec.android.iap.lib.R;
import com.sec.android.iap.lib.helper.SamsungIapHelper;
import com.sec.android.iap.lib.listener.OnGetInboxListener;
import com.sec.android.iap.lib.listener.OnGetItemListener;
import com.sec.android.iap.lib.listener.OnIapBindListener;
import com.sec.android.iap.lib.listener.OnPaymentListener;
import com.sec.android.iap.lib.vo.ErrorVo;
import com.sec.android.iap.lib.vo.InboxVo;
import com.sec.android.iap.lib.vo.ItemVo;
import com.sec.android.iap.lib.vo.PurchaseVo;


public abstract class BaseActivity extends Activity
{
    private static final String  TAG = BaseActivity.class.getSimpleName();
    
    /**
     * Set mode to {@link SamsungIapHelper#IAP_MODE_COMMERCIAL} to make real financial transaction.
     * Please double-check this mode before release.
     */
    private int mIapMode = SamsungIapHelper.IAP_MODE_COMMERCIAL;
    
    protected ErrorVo               mErrorVo            = new ErrorVo();
    protected PurchaseVo            mPurchaseVo         = null;
    protected ArrayList<ItemVo>     mItemList           = null;
    protected ArrayList<InboxVo>    mInbox              = null;
    private   Dialog                mProgressDialog     = null;
    
    /**
     * Helper Class between IAPService and 3rd Party Application
     */
    SamsungIapHelper                mSamsungIapHelper   = null;
    
    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        // 1. Store IapMode passed by Intent
        // ====================================================================
        Intent intent = getIntent();
        
        if( intent != null
                && intent.getExtras() != null
                && intent.getExtras().containsKey( "IapMode" ) )
        {
            Bundle extras = intent.getExtras();
            mIapMode = extras.getInt( "IapMode" );
        }
        // ====================================================================

        // 2. SamsungIapHelper Instance creation
        //    To test on development, set mode to test mode using
        //    use SamsungIapHelper.IAP_MODE_TEST_SUCCESS or
        //    SamsungIapHelper.IAP_MODE_TEST_FAIL constants.
        // ====================================================================
        mSamsungIapHelper = SamsungIapHelper.getInstance( this, mIapMode );
        // ====================================================================
       
        // 3. This activity is invisible excepting progress bar as default.
        // ====================================================================
        try
        {
            mProgressDialog = new Dialog( this, R.style.Theme_Empty );
            mProgressDialog.setContentView( R.layout.progress_dialog );
            mProgressDialog.setCancelable( false );
            mProgressDialog.show();
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
        // ====================================================================
        
        super.onCreate(savedInstanceState);
    }
    
    public void setItemList( ArrayList<ItemVo> _itemList )
    {
        mItemList = _itemList;
    }
    
    public void setPurchaseVo( PurchaseVo  _purchaseVo )
    {
        mPurchaseVo = _purchaseVo;
    }
    
    public void setInbox( ArrayList<InboxVo> _inbox )
    {
        mInbox = _inbox;
    }
    
    public void setErrorVo( ErrorVo _errorVo )
    {
        mErrorVo = _errorVo;
    }
    
    public boolean checkIapPackage()
    {
        // 1. If IAP Package is installed in your device
        // ====================================================================
        if( true == mSamsungIapHelper.isInstalledIapPackage( this ) )
        {
            // 1) If IAP package installed in your device is valid
            // ================================================================
            if( true == mSamsungIapHelper.isValidIapPackage( this ) )
            {
                return true;
            }
            // ================================================================
            // 2) If IAP package installed in your device is not valid
            // ================================================================            
            else
            {
                // Set error to notify result to third-party application
                // ------------------------------------------------------------
                mErrorVo.setError( SamsungIapHelper.IAP_ERROR_COMMON,
                                   getString(R.string.IDS_SAPPS_POP_YOUR_PURCHASE_VIA_SAMSUNG_IN_APP_PURCHASE_IS_INVALID_A_FAKE_APPLICATION_HAS_BEEN_DETECTED_CHECK_THE_APP_MSG) );
                // ------------------------------------------------------------
                // show alert dialog if IAP Package is invalid
                // ------------------------------------------------------------
                mSamsungIapHelper.showIapDialog( this,
                                                 getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ),           
                                                 getString( R.string.IDS_SAPPS_POP_YOUR_PURCHASE_VIA_SAMSUNG_IN_APP_PURCHASE_IS_INVALID_A_FAKE_APPLICATION_HAS_BEEN_DETECTED_CHECK_THE_APP_MSG ),
                                                 true,
                                                 null );
                // ------------------------------------------------------------
            }
            // ================================================================
        }
        // ====================================================================
        // 2. If IAP Package is not installed in your device
        // ====================================================================
        else
        {
            mSamsungIapHelper.installIapPackage( this );
        }
        // ====================================================================
        
        return false;
    }
    
    /**
     * Binding to IAPService
     * Once IAPService bound successfully, invoke succeedBind() method.
     */
    public void bindIapService()
    {
        Log.i( TAG, "start Bind... ");
        
        // 1. Bind to IAPService
        // ====================================================================
        mSamsungIapHelper.bindIapService( new OnIapBindListener()
        {
            @Override
            public void onBindIapFinished( int _result )
            {
                Log.i( TAG, "Binding OK... ");
                
                // 1) If IAPService is bound successfully.
                // ============================================================
                if( _result == SamsungIapHelper.IAP_RESPONSE_RESULT_OK )
                {
                    succeedBind();
                }
                // ============================================================
                // 2) If IAPService is not bound.
                // ============================================================
                else
                {
                    // a) Set error for notifying result to third-party
                    //    application
                    // --------------------------------------------------------
                    mErrorVo.setError( SamsungIapHelper.IAP_ERROR_COMMON,
                                       getString(R.string.IDS_SAPPS_POP_YOUR_PURCHASE_VIA_SAMSUNG_IN_APP_PURCHASE_IS_INVALID_A_FAKE_APPLICATION_HAS_BEEN_DETECTED_CHECK_THE_APP_MSG) );
                    // --------------------------------------------------------
                    // b) show alert dialog when bind is failed
                    // --------------------------------------------------------
                    mSamsungIapHelper.showIapDialog( BaseActivity.this,
                                                     getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ),
                                                     getString( R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED )
                                                         + "[Lib_Bind]",
                                                     true,
                                                     null );
                    // --------------------------------------------------------
                }
                // ============================================================
            }
        });
        // ====================================================================
    }
    
    @Override
    protected void onDestroy() 
    {
        // 1. dismiss ProgressDialog
        // ====================================================================
        try
        {
            if( mProgressDialog != null )
            {
                mProgressDialog.dismiss();
                mProgressDialog = null;
            }
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
        // ====================================================================
        
        // 2. Invoke Callback Method to notify result to third-party
        //    application.
        // ====================================================================
        if( null != mSamsungIapHelper )
        {
            OnGetInboxListener onGetInboxListener
                                   = mSamsungIapHelper.getOnGetInboxListener();
            
            if( null != onGetInboxListener ) 
            {
                onGetInboxListener.onGetItemInbox( mErrorVo, mInbox );
            }

            OnGetItemListener onItemListener
                                    = mSamsungIapHelper.getOnGetItemListener();

            if( null != onItemListener ) 
            {
                onItemListener.onGetItem(mErrorVo, mItemList);
            }

            OnPaymentListener onPaymentListener = 
                                      mSamsungIapHelper.getOnPaymentListener();

            if( null != onPaymentListener ) 
            {
                onPaymentListener.onPayment(mErrorVo, mPurchaseVo);
            }
            
            // Unbind from IAPService. and releases the used resources.
            // ----------------------------------------------------------------
            mSamsungIapHelper.removeAllListener();
            mSamsungIapHelper.dispose();
            mSamsungIapHelper = null;
            // ----------------------------------------------------------------
        }
        // ====================================================================
        
        super.onDestroy();
    }

    abstract void succeedBind();
}