package com.sec.android.iap.lib.vo;

import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

public class PurchaseVo extends BaseVo
{
    private static final String TAG = PurchaseVo.class.getSimpleName();

    private String mPaymentId;
    private String mPurchaseId;
    private String mPurchaseDate;
    private String mVerifyUrl;
    private String mJsonString;

    public PurchaseVo( String _jsonString )
    {
        super( _jsonString );

        setJsonString( _jsonString );
        Log.i( TAG, mJsonString );
        
        try
        {
            JSONObject jObject = new JSONObject( _jsonString );

            setPaymentId( jObject.optString( "mPaymentId" ) );
            setPurchaseId( jObject.optString( "mPurchaseId" ) );
            
            setPurchaseDate( 
                       getDateString( jObject.optLong( "mPurchaseDate" ) ) );
            
            setVerifyUrl( jObject.optString( "mVerifyUrl" ) );
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
    
    public String getPurchaseId()
    {
        return mPurchaseId;
    }

    public void setPurchaseId( String _purchaseId )
    {
        mPurchaseId = _purchaseId;
    }

    public String getPurchaseDate()
    {
        return mPurchaseDate;
    }

    public void setPurchaseDate( String _purchaseDate )
    {
        mPurchaseDate = _purchaseDate;
    }

    public String getVerifyUrl()
    {
        return mVerifyUrl;
    }
    
    public void setVerifyUrl(String _verifyUrl)
    {
        mVerifyUrl = _verifyUrl;
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
        
        dump += "PaymentID    : " + getPaymentId()    + "\n" +
                "PurchaseId   : " + getPurchaseId()   + "\n" +
                "PurchaseDate : " + getPurchaseDate() + "\n" +
                "VerifyUrl    : " + getVerifyUrl();
        
        return dump;
    }
}