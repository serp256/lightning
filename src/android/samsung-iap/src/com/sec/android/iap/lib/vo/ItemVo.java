package com.sec.android.iap.lib.vo;

import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

public class ItemVo extends BaseVo
{
    private static final String TAG = ItemVo.class.getSimpleName();
    
    private String mType;
    private String mSubscriptionDurationUnit;
    private String mSubscriptionDurationMultiplier;
    private String mJsonString;
    
    public ItemVo(){}

    public ItemVo( String _jsonString )
    {
        super( _jsonString );
        
        setJsonString( _jsonString );
        Log.i( TAG, mJsonString );
        
        try
        {
            JSONObject jObject = new JSONObject( _jsonString );
            
            setType( jObject.optString( "mType" ) );
                
            setSubscriptionDurationUnit( 
                            jObject.optString( "mSubscriptionDurationUnit" ) );
                
            setSubscriptionDurationMultiplier( 
                      jObject.optString( "mSubscriptionDurationMultiplier" ) );
        }
        catch( JSONException e )
        {
            e.printStackTrace();
        }
    }

    public String getType()
    {
        return mType;
    }

    public void setType( String _type )
    {
        mType = _type;
    }
    
    public String getSubscriptionDurationUnit()
    {
        return mSubscriptionDurationUnit;
    }

    public void setSubscriptionDurationUnit( String _subscriptionDurationUnit )
    {
        mSubscriptionDurationUnit = _subscriptionDurationUnit;
    }

    public String getSubscriptionDurationMultiplier()
    {
        return mSubscriptionDurationMultiplier;
    }

    public void setSubscriptionDurationMultiplier(
                                       String _subscriptionDurationMultiplier )
    {
        mSubscriptionDurationMultiplier = _subscriptionDurationMultiplier;
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
        
        dump += "Type : " + getType() + "\n" +
                "SubscriptionDurationUnit : "
                                       + getSubscriptionDurationUnit() + "\n" +
                "SubscriptionDurationMultiplier : " + 
                                           getSubscriptionDurationMultiplier();
        return dump;
    }
}