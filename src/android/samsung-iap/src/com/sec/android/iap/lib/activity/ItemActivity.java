package com.sec.android.iap.lib.activity;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

import com.sec.android.iap.lib.R;
import com.sec.android.iap.lib.helper.SamsungIapHelper;

public class ItemActivity extends BaseActivity
{
    @SuppressWarnings("unused")
    private static final String  TAG = ItemActivity.class.getSimpleName();

    /** Item Group ID of 3rd Party Application */
    private String            mItemGroupId       = null;

    /**
     *  Item Type
     *  Consumable      : 00 {@link SamsungIapHelper#ITEM_TYPE_CONSUMABLE}
     *  Non Consumable  : 01 {@link SamsungIapHelper#ITEM_TYPE_NON_CONSUMABLE}
     *  Subscription    : 02 {@link SamsungIapHelper#ITEM_TYPE_SUBSCRIPTION}
     *  All             : 10 {@link SamsungIapHelper#ITEM_TYPE_ALL}
     */
    private String            mItemType          = null;
    
    private int               mStartNum          = 1;
    private int               mEndNum            = 15;
    
    @Override
    protected void onCreate( Bundle savedInstanceState )
    {
        super.onCreate( savedInstanceState );
        
        // 1. save ItemGroupId, StartNum, EndNum and ItemType passed by Intent
        // ====================================================================
        Intent intent = getIntent();
        
        if( intent != null && intent.getExtras() != null 
                && intent.getExtras().containsKey( "ItemGroupId" )
                && intent.getExtras().containsKey( "StartNum" )
                && intent.getExtras().containsKey( "EndNum" )
                && intent.getExtras().containsKey( "ItemType" ) )
        {
            Bundle extras = intent.getExtras();

            mItemGroupId = extras.getString( "ItemGroupId" );
            mStartNum    = extras.getInt( "StartNum" );
            mEndNum      = extras.getInt( "EndNum" );
            mItemType    = extras.getString( "ItemType" );
        }
        else
        {
            Toast.makeText( this, 
                            R.string.IDS_SAPPS_POP_AN_INVALID_VALUE_HAS_BEEN_PROVIDED_FOR_SAMSUNG_IN_APP_PURCHASE,
                            Toast.LENGTH_LONG ).show();
            
            // Set error to notify result to third-party application
            // ----------------------------------------------------------------
            mErrorVo.setError( SamsungIapHelper.IAP_ERROR_COMMON,
                               getString(R.string.IDS_SAPPS_POP_AN_INVALID_VALUE_HAS_BEEN_PROVIDED_FOR_SAMSUNG_IN_APP_PURCHASE) );
            // ----------------------------------------------------------------
            
            finish();
            return;
        }
        // ====================================================================
        // 2. If IAP package is installed and valid,
        // bind to IAPService to load item list.
        // ====================================================================
        if( checkIapPackage() == true )
        {
            bindIapService();
        }
        // ====================================================================
    }
    
    /**
     * If binding to IAPService is successful, this method is invoked.
     * This method loads the item list through IAPService.
     */
    protected void succeedBind()
    {
        mSamsungIapHelper.safeGetItemList( ItemActivity.this,
                                           mItemGroupId,
                                           mStartNum,
                                           mEndNum,
                                           mItemType );
    }
}