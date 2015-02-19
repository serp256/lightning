package com.sec.android.iap.lib.activity;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

import com.sec.android.iap.lib.R;
import com.sec.android.iap.lib.helper.SamsungIapHelper;

public class InboxActivity extends BaseActivity
{
    @SuppressWarnings("unused")
    private static final String  TAG = InboxActivity.class.getSimpleName();
    
    /** Item Group ID of 3rd Party Application */ 
    private String           mItemGroupId      = null;
    
    private int              mStartNum         = 0;
    private int              mEndNum           = 0;
    private String           mStartDate        = "";
    private String           mEndDate          = "";
    
    @Override
    protected void onCreate( Bundle savedInstanceState )
    {
        super.onCreate( savedInstanceState );
        
        // 1. Save ItemGroupId, StartNum, EndNum, StartDate and EndDate
        //    passed by Intent
        // ====================================================================
        Intent intent = getIntent();
        
        if( intent != null 
                && intent.getExtras() != null 
                && intent.getExtras().containsKey( "ItemGroupId" ) 
                && intent.getExtras().containsKey( "StartNum" )
                && intent.getExtras().containsKey( "EndNum" )
                && intent.getExtras().containsKey( "StartDate" )
                && intent.getExtras().containsKey( "EndDate" ) )
        {
            Bundle extras = intent.getExtras();

            mItemGroupId = extras.getString( "ItemGroupId" );
            mStartNum    = extras.getInt( "StartNum" );        
            mEndNum      = extras.getInt( "EndNum" );
            mStartDate   = extras.getString( "StartDate" );         
            mEndDate     = extras.getString( "EndDate" );
        }
        else
        {
            Toast.makeText( this, 
                            R.string.IDS_SAPPS_POP_AN_INVALID_VALUE_HAS_BEEN_PROVIDED_FOR_SAMSUNG_IN_APP_PURCHASE,
                            Toast.LENGTH_LONG ).show();
            
            // Set error to return result to third-party application
            // ----------------------------------------------------------------
            mErrorVo.setError( SamsungIapHelper.IAP_ERROR_COMMON,
                               getString(R.string.IDS_SAPPS_POP_AN_INVALID_VALUE_HAS_BEEN_PROVIDED_FOR_SAMSUNG_IN_APP_PURCHASE) );
            // ----------------------------------------------------------------
            
            finish();
        }
        // ====================================================================

        // 2. If IAP package is installed and valid, Start SamsungAccount
        //    authentication step to load purchased item list.
        // ====================================================================
        if( true == checkIapPackage() )
        {
            mSamsungIapHelper.startAccountActivity( this );
        }
        // ====================================================================
    }
    
    /**
     * handle result of SamsungAccount authentication.
     */
    @Override
    protected void onActivityResult
    (   
        int     _requestCode,
        int     _resultCode,
        Intent  _intent
    )
    {
        switch( _requestCode )
        {
            // Handle authentication result of SamsungAccount
            // ================================================================
            case SamsungIapHelper.REQUEST_CODE_IS_ACCOUNT_CERTIFICATION :
            {
                // 1) If SamsungAccount authentication is successful
                // ------------------------------------------------------------
                if( RESULT_OK == _resultCode )
                {
                    // bind to IAPService. 
                    // Once bound, invoke succeedBind()
                    // method to load purchased list.
                    // --------------------------------------------------------
                    bindIapService();
                    // --------------------------------------------------------
                }
                // ------------------------------------------------------------
                // 2) If SamsungAccount authentication is cancelled
                // ------------------------------------------------------------
                else if( RESULT_CANCELED == _resultCode )
                {
                    mErrorVo.setError( SamsungIapHelper.IAP_PAYMENT_IS_CANCELED,
                                       getString( R.string.IDS_SAPPS_POP_PAYMENT_CANCELLED ) );
                    
                    mSamsungIapHelper.showIapDialog( InboxActivity.this,
                                                     getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ),
                                                     getString( R.string.IDS_SAPPS_POP_PAYMENT_CANCELLED ),
                                                     true,
                                                     null );
                }
                // ------------------------------------------------------------
                break;
            }
            // ================================================================
        }
    }
    
    /**
     * If binding to IAPService was successful, this method is invoked.
     * This Method loads the purchased list through IAPService.
     */
    protected void succeedBind()
    {
        mSamsungIapHelper.safeGetItemInboxTask( InboxActivity.this, 
                                                mItemGroupId,
                                                mStartNum,
                                                mEndNum,
                                                mStartDate,
                                                mEndDate );
    }
}