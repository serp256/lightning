package com.sec.android.iap.lib.vo;

import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

public class InboxVo extends BaseVo
{
    private static final String TAG = InboxVo.class.getSimpleName();

    private String mType;
    private String mPaymentId;
    private String mPurchaseDate;
    
    // Expiration date for a item which is ITEM_TYPE_SUBSCRIPTION("02") type
    // ========================================================================
    private String mSubscriptionEndDate;
    // ========================================================================
    
    private String mJsonString = "";
    
    public InboxVo( String _jsonString )
    {
        super( _jsonString );

        setJsonString( _jsonString );
        Log.i( TAG, mJsonString );
        
        try
        {
            JSONObject jObject = new JSONObject( _jsonString );
            
            setType( jObject.optString( "mType" ) );
            setPaymentId( jObject.optString( "mPaymentId" ) );
            setPurchaseDate( 
                       getDateString( jObject.optLong( "mPurchaseDate" ) ) );
            setSubscriptionEndDate(
                getDateString( jObject.optLong( "mSubscriptionEndDate" ) ) );
        }
        catch( JSONException e )
        {
            e.printStackTrace();
        }
    }

    public String getPaymentId()
    {
        return mPaymentId;
    }

    public void setPaymentId( String _paymentId )
    {
        mPaymentId = _paymentId;
    }

    public String getPurchaseDate()
    {
        return mPurchaseDate;
    }

    public void setPurchaseDate( String _purchaseDate )
    {
        mPurchaseDate = _purchaseDate;
    }

    
    public String getSubscriptionEndDate()
    {
        return mSubscriptionEndDate;
    }

    public void setSubscriptionEndDate( String _subscriptionEndDate )
    {
        mSubscriptionEndDate = _subscriptionEndDate;
    }
    
    public String getType()
    {
        return mType;
    }

    public void setType( String _type )
    {
        mType = _type;
    }
    
    public String getJsonString()
    {
        return mJsonString;
    }

    public void setJsonString( String _jsonString )
    {
        mJsonString = _jsonString;
    }
    
    public String dump()
    {
        String dump = super.dump() + "\n";
        
        dump += "Type                : " + getType()                + "\n" + 
                "PurchaseDate        : " + getPurchaseDate()        + "\n" +
                "SubscriptionEndDate : " + getSubscriptionEndDate() + "\n" +
                "PaymentID           : " + getPaymentId();
        
        return dump;
    }
}