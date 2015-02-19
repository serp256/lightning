package com.sec.android.iap.lib.vo;

import org.json.JSONException;
import org.json.JSONObject;

import android.text.format.DateFormat;

public class BaseVo 
{
    private String mItemId;
    private String mItemName;
    private Double mItemPrice;
    private String mItemPriceString;
    private String mCurrencyUnit;
    private String mItemDesc;
    private String mItemImageUrl;
    private String mItemDownloadUrl;
    
    public BaseVo(){}

    public BaseVo( String _jsonString )
    {
        try
        {
            JSONObject jObject = new JSONObject( _jsonString );
            
            setItemId( jObject.optString( "mItemId" ) );
            setItemName( jObject.optString( "mItemName" ) );
            setItemPrice( jObject.optDouble("mItemPrice" ) );
            setCurrencyUnit( jObject.optString( "mCurrencyUnit" ) );
            setItemDesc( jObject.optString( "mItemDesc" ) );
            setItemImageUrl( jObject.optString( "mItemImageUrl" ) );
            setItemDownloadUrl( jObject.optString( "mItemDownloadUrl" ) );
            setItemPriceString( jObject.optString( "mItemPriceString" ) );
        }
        catch( JSONException e )
        {
            e.printStackTrace();
        }
    }

    public String getItemId()
    {
        return mItemId;
    }

    public void setItemId( String _itemId )
    {
        mItemId = _itemId;
    }

    public String getItemName()
    {
        return mItemName;
    }

    public void setItemName( String _itemName )
    {
        mItemName = _itemName;
    }

    public Double getItemPrice()
    {
        return mItemPrice;
    }

    public void setItemPrice( Double _itemPrice )
    {
        mItemPrice = _itemPrice;
    }
    
    public String getItemPriceString()
    {
        return mItemPriceString;
    }

    public void setItemPriceString( String _itemPriceString )
    {
        mItemPriceString = _itemPriceString;
    }

    public String getCurrencyUnit()
    {
        return mCurrencyUnit;
    }

    public void setCurrencyUnit( String _currencyUnit )
    {
        mCurrencyUnit = _currencyUnit;
    }

    public String getItemDesc()
    {
        return mItemDesc;
    }

    public void setItemDesc( String _itemDesc )
    {
        mItemDesc = _itemDesc;
    }

    public String getItemImageUrl()
    {
        return mItemImageUrl;
    }

    public void setItemImageUrl( String _itemImageUrl )
    {
        mItemImageUrl = _itemImageUrl;
    }

    public String getItemDownloadUrl()
    {
        return mItemDownloadUrl;
    }

    public void setItemDownloadUrl( String _itemDownloadUrl )
    {
        mItemDownloadUrl = _itemDownloadUrl;
    }

    public String dump()
    {
        String dump = null;
        
        dump = "ItemId          : " + getItemId()          + "\n" + 
               "ItemName        : " + getItemName()        + "\n" +
               "ItemPrice       : " + getItemPrice()       + "\n" +
               "ItemPriceString : " + getItemPriceString() + "\n" +
               "CurrencyUnit    : " + getCurrencyUnit()    + "\n" +
               "ItemDesc        : " + getItemDesc()        + "\n" +
               "ItemImageUrl    : " + getItemImageUrl()    + "\n" +
               "ItemDownloadUrl : " + getItemDownloadUrl();
        
        return dump;
    }
    
    protected String getDateString( long _timeMills )
    {
        String result     = "";
        String dateFormat = "yyyy.MM.dd hh:mm:ss";
        
        try
        {
            result = DateFormat.format( dateFormat, _timeMills ).toString();
        }
        catch( Exception e )
        {
            e.printStackTrace();
            result = "";
        }
        
        return result;
    }
}