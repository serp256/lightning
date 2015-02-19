package com.sec.android.iap.lib.helper;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.AsyncTask.Status;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.text.TextUtils;
import android.util.Log;

import com.sec.android.iap.IAPConnector;
import com.sec.android.iap.lib.R;
import com.sec.android.iap.lib.activity.BaseActivity;
import com.sec.android.iap.lib.activity.InboxActivity;
import com.sec.android.iap.lib.activity.ItemActivity;
import com.sec.android.iap.lib.activity.PaymentActivity;
import com.sec.android.iap.lib.listener.OnGetInboxListener;
import com.sec.android.iap.lib.listener.OnGetItemListener;
import com.sec.android.iap.lib.listener.OnIapBindListener;
import com.sec.android.iap.lib.listener.OnInitIapListener;
import com.sec.android.iap.lib.listener.OnPaymentListener;
import com.sec.android.iap.lib.vo.ErrorVo;
import com.sec.android.iap.lib.vo.InboxVo;
import com.sec.android.iap.lib.vo.ItemVo;
import com.sec.android.iap.lib.vo.PurchaseVo;
import com.sec.android.iap.lib.vo.VerificationVo;

public class SamsungIapHelper
{
    private static final String TAG  = SamsungIapHelper.class.getSimpleName();
    private static final int    HONEYCOMB_MR1                   = 12;
    private static final int    FLAG_INCLUDE_STOPPED_PACKAGES   = 32;

    // IAP Signature HashCode - Used to validate IAP package
    // ========================================================================
    public static final int     IAP_SIGNATURE_HASHCODE          = 0x7a7eaf4b;
    // ========================================================================
    
    // Name of IAP Package and Service
    // ========================================================================
    public static final String  IAP_PACKAGE_NAME = "com.sec.android.iap";
    public static final String  IAP_SERVICE_NAME = 
                                      "com.sec.android.iap.service.iapService";
    // ========================================================================

    // result code for binding to IAPService
    // ========================================================================
    public static final int     IAP_RESPONSE_RESULT_OK          = 0;
    public static final int     IAP_RESPONSE_RESULT_UNAVAILABLE = 2;
    // ========================================================================

    // BUNDLE KEY
    // ========================================================================
    public static final String  KEY_NAME_THIRD_PARTY_NAME = "THIRD_PARTY_NAME";
    public static final String  KEY_NAME_STATUS_CODE      = "STATUS_CODE";
    public static final String  KEY_NAME_ERROR_STRING     = "ERROR_STRING";
    public static final String  KEY_NAME_IAP_UPGRADE_URL  = "IAP_UPGRADE_URL";
    public static final String  KEY_NAME_ITEM_GROUP_ID    = "ITEM_GROUP_ID";
    public static final String  KEY_NAME_ITEM_ID          = "ITEM_ID";
    public static final String  KEY_NAME_RESULT_LIST      = "RESULT_LIST";
    public static final String  KEY_NAME_RESULT_OBJECT    = "RESULT_OBJECT";
    // ========================================================================

    // Item Type
    // ------------------------------------------------------------------------
    // Consumable      : 00
    // Non Consumable  : 01
    // Subscription    : 02
    // All             : 10
    // ========================================================================
    public static final String ITEM_TYPE_CONSUMABLE       = "00";
    public static final String ITEM_TYPE_NON_CONSUMABLE   = "01";
    public static final String ITEM_TYPE_SUBSCRIPTION     = "02";
    public static final String ITEM_TYPE_ALL              = "10";
    // ========================================================================

    // Define request code to IAPService.
    // ========================================================================
    public static final int   REQUEST_CODE_IS_IAP_PAYMENT            = 1;
    public static final int   REQUEST_CODE_IS_ACCOUNT_CERTIFICATION  = 2;
    // ========================================================================
    
    // Define status code notify to 3rd-party application 
    // ========================================================================
    /** Success */
    final public static int IAP_ERROR_NONE                   = 0;
    
    /** Payment is cancelled */
    final public static int IAP_PAYMENT_IS_CANCELED          = 1;
    
    /** IAP initialization error */
    final public static int IAP_ERROR_INITIALIZATION         = -1000;
    
    /** IAP need to be upgraded */
    final public static int IAP_ERROR_NEED_APP_UPGRADE       = -1001;
    
    /** Common error */
    final public static int IAP_ERROR_COMMON                 = -1002;
    
    /** Repurchase NON-CONSUMABLE item */
    final public static int IAP_ERROR_ALREADY_PURCHASED      = -1003;
    
    /** When PaymentMethodList Activity is called without Bundle data */
    final public static int IAP_ERROR_WHILE_RUNNING          = -1004;
    
    /** does not exist item or item group id */
    final public static int IAP_ERROR_PRODUCT_DOES_NOT_EXIST = -1005;
    
    /**
     * After purchase request not received the results can not be determined
     * whether to buy. So, the confirmation of purchase list is needed.
     */
    final public static int IAP_ERROR_CONFIRM_INBOX          = -1006;
    // ========================================================================

    // IAP Mode
    // ========================================================================
    /** Test mode for development. Always return true. */
    final public static int IAP_MODE_TEST_SUCCESS             =  1;
    
    /** Test mode for development. Always return failed. */
    final public static int IAP_MODE_TEST_FAIL                = -1;
    
    /** Production mode. Set mode to this to charge for your item. */
    final public static int IAP_MODE_COMMERCIAL               =  0;
    
    /**
     * When you release a application,
     * this Mode must be set to {@link SamsungIapHelper#IAP_MODE_COMMERCIAL}
     * Please double-check this mode before release.
     */
    private int                   mMode = IAP_MODE_TEST_SUCCESS;
    // ========================================================================
    
    private Context               mContext         = null;

    private IAPConnector          mIapConnector    = null;
    private ServiceConnection     mServiceConn     = null;
    
    // AsyncTask for IAPService Initialization
    // ========================================================================
    private InitIapTask           mInitIapTask            = null;
    private OnInitIapListener     mOnInitIapListener      = null;
    // ========================================================================
    
    // AsyncTask for get item list
    // ========================================================================
    private GetItemListTask       mGetItemListTask        = null;
    private OnGetItemListener     mOnGetItemListener      = null;
    // ========================================================================

    // AsyncTask for get inbox list
    // ========================================================================
    private GetInboxListTask      mGetInboxListTask       = null;
    private OnGetInboxListener    mOnGetInboxListener     = null;
    // ========================================================================

    // Validate a purchase
    // This is fixed.
    // ========================================================================
    private static final String VERIFY_URL = "https://iap.samsungapps.com/iap/"
                                                + "appsItemVerifyIAPReceipt.as"
                                                + "?protocolVersion=2.0";
    
    private VerifyClientToServer   mVerifyClientToServer  = null;
    // ========================================================================
    
    private OnPaymentListener      mOnPaymentListener     = null;
    
    private static SamsungIapHelper mInstance = null;
    
    // State of IAP Service
    // ========================================================================
    private int mState = STATE_TERM;
    
    /** initial state */
    private static final int STATE_TERM     = 0;
    
    /** state of bound to IAPService successfully */
    private static final int STATE_BINDING  = 1;
    
    /** state of InitIapTask successfully finished */
    private static final int STATE_READY    = 2; // 
    // ========================================================================
    
    
    
    
    
    // ########################################################################
    // ########################################################################
    // 1. SamsungIAPHeler object create and reference
    // ########################################################################
    // ########################################################################

    /**
     * SamsungIapHelper constructor
     * @param _context
     * @param _mode
     */
    private SamsungIapHelper( Context _context , int _mode )
    {
        _setContextAndMode( _context, _mode );
    }
    
    /**
     * SamsungIapHelper singleton reference method
     * @param _context Context
     * @param _mode IAP mode
     */
    public static SamsungIapHelper getInstance( Context _context, int _mode )
    {
        if( null == mInstance )
        {
            mInstance = new SamsungIapHelper( _context, _mode );
        }
        else
        {
            mInstance._setContextAndMode( _context, _mode );
        }
        
        return mInstance;
    }
    
    private void _setContextAndMode( Context _context, int _mode )
    {
        mContext = _context.getApplicationContext();
        mMode    = _mode;        
    }
        

    

    
    // ########################################################################
    // ########################################################################
    // 2. Initialize for IAPService
    //    ( SamsungAccount authentication, Binding, init )
    // ########################################################################
    // ########################################################################
    
    ///////////////////////////////////////////////////////////////////////////
    // 2.1) SamsungAccount authentication//////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    /**
     * SamsungAccount authentication
     * @param _activity
     */
    public void startAccountActivity( final Activity _activity )
    {
        ComponentName com = new ComponentName( "com.sec.android.iap", 
                              "com.sec.android.iap.activity.AccountActivity" );

        Intent intent = new Intent();
        intent.setComponent( com );

        _activity.startActivityForResult( intent,
                                       REQUEST_CODE_IS_ACCOUNT_CERTIFICATION );
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // 2.2) binding ///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    /**
     * bind to IAPService
     *  
     * @param _listener The listener that receives notifications
     * when bindIapService method is finished.
     */
    public void bindIapService( final OnIapBindListener _listener )
    {
        // exit If already bound 
        // ====================================================================
        if( mState >= STATE_BINDING )
        {
            if( _listener != null )
            {
                _listener.onBindIapFinished( IAP_RESPONSE_RESULT_OK );
            }
            
            return;
        }
        // ====================================================================

        // Connection to IAP service
        // ====================================================================
        mServiceConn = new ServiceConnection()
        {
            @Override
            public void onServiceDisconnected( ComponentName _name )
            {
                Log.d( TAG, "IAP Service Disconnected..." );

                mState        = STATE_TERM;
                mIapConnector = null;
                mServiceConn  = null;
            }

            @Override
            public void onServiceConnected
            (   
                ComponentName _name,
                IBinder       _service
            )
            {
                mIapConnector = IAPConnector.Stub.asInterface( _service );

                if( mIapConnector != null && _listener != null )
                {
                    mState = STATE_BINDING;
                    
                    _listener.onBindIapFinished( IAP_RESPONSE_RESULT_OK );
                }
                else
                {
                    mState = STATE_TERM;
                    
                    _listener.onBindIapFinished( 
                                             IAP_RESPONSE_RESULT_UNAVAILABLE );
                }
            }
        };
        // ====================================================================
        Intent serviceIntent = new Intent();
        serviceIntent.setComponent(new ComponentName("com.sec.android.iap", 
                                    "com.sec.android.iap.service.IAPService"));
        // bind to IAPService
        // ====================================================================
        mContext.bindService( serviceIntent, 
                              mServiceConn,
                              Context.BIND_AUTO_CREATE );
        // ====================================================================
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // 2.3) init //////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    /**
     * execute {@link InitIapTask}
     */
    public void safeInitIap( BaseActivity _activity )
    {
        try
        {
            if( mInitIapTask != null &&
                mInitIapTask.getStatus() != Status.FINISHED )
            {
                mInitIapTask.cancel( true );
            }

            mInitIapTask = new InitIapTask( _activity );
            mInitIapTask.execute();
        }
        catch( Exception e )
        {
            if( null != _activity )
            {
                _activity.finish();
            }
            
            e.printStackTrace();
        }
    }
    
    /**
     * AsyncTask for initializing of IAPService
     */
    private class InitIapTask  extends AsyncTask<String, Object, Boolean>
    {
        private BaseActivity    mActivity  = null;
        private ErrorVo         mErrorVo   = new ErrorVo();
        
        public InitIapTask( BaseActivity _activity )
        {
            mActivity = _activity;
            
            mActivity.setErrorVo( mErrorVo );
        }
        
        @Override
        protected Boolean doInBackground( String... params )
        {
            try
            {
                // Initialize IAPService by calling init() method of IAPService
                // ============================================================
                if( mState == STATE_READY )
                {
                    mErrorVo.setError( IAP_ERROR_NONE, "" );
                }
                else
                {
                    Log.i( TAG, "start Init... ");
                    
                    init( mErrorVo );
                    
                    Log.i( TAG, "end Init... ");
                }
                // ============================================================
                
                return true;
            }
            catch( Exception e )
            {
                mErrorVo.setError( 
                        IAP_ERROR_INITIALIZATION, 
                        mActivity.getString( 
                             R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED ) );
                
                e.printStackTrace();
                
                return false;
            }
        }

        @Override
        protected void onPostExecute( Boolean result )
        {
            // 1. If InitTask return true
            // ================================================================
            if( true == result )
            {
                // 1) If the initialization is finished successfully
                // ============================================================
                if( mErrorVo.getErrorCode() == IAP_ERROR_NONE )
                {
                    // invoke Callback method onSucceedInitIap()
                    // --------------------------------------------------------
                    if( null != mOnInitIapListener )
                    {
                        mState = STATE_READY;
                        mOnInitIapListener.onSucceedInitIap();
                    }
                    // --------------------------------------------------------
                }
                // 2) If the IAP package needs to be upgraded
                // ============================================================
                else if( mErrorVo.getErrorCode() == IAP_ERROR_NEED_APP_UPGRADE )
                {
                    // When user click the OK button on the dialog,
                    // go to SamsungApps IAP Detail page
                    // --------------------------------------------------------
                    Runnable OkBtnRunnable = new Runnable()
                    {
                        @Override
                        public void run()
                        {
                            if( true == TextUtils.isEmpty( 
                                                  mErrorVo.getExtraString() ) )
                            {
                                return;
                            }
                            
                            Intent intent = new Intent(Intent.ACTION_VIEW);
                            
                            intent.setData( 
                                      Uri.parse( mErrorVo.getExtraString() ) );
                            
                            intent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK );

                            try
                            {
                                mActivity.startActivity( intent );
                            }
                            catch( ActivityNotFoundException e )
                            {
                                e.printStackTrace();
                            }
                        }
                    };
                    // --------------------------------------------------------
                    
                    // Pop-up shows that "the IAP package needs to be updated" in local language.
                    // --------------------------------------------------------
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                                   mErrorVo.getErrorString(),
                                   true,
                                   OkBtnRunnable );
                    // --------------------------------------------------------
                }
                // ============================================================
                // 3) If IAPService initialization is failed
                // ============================================================
                else
                {
                    // Pop-up shows that the initialization is failed.
                    // --------------------------------------------------------
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                                   mErrorVo.getErrorString(), 
                                   true,
                                   null );
                    // --------------------------------------------------------
                }
                // ============================================================
            }
            // ================================================================
            // 2. InitIAPTask returned false by occurring unknown exception
            // ================================================================
            else
            {
                showIapDialog( mActivity,
                               mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                               mActivity.getString( R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED )
                                   + "[Lib_Init]",
                               true,
                               null );
            }
            // ================================================================
        }
    }
    
    /**
     * Register a callback interface to be invoked
     * when {@link InitIapTask} has been finished.
     * @param _onInitIapListener callback listener after IAP is initialized.
     */
    public void setOnInitIapListener( OnInitIapListener _onInitIapListener )
    {
        mOnInitIapListener = _onInitIapListener;
    }
    
    /**
     * process IAP initialization by calling init() interface in IAPConnector
     * @param _errorVo
     */
    public void init( ErrorVo _errorVo)
    {
        try
        {
            Bundle bundle = mIapConnector.init( mMode );
            
            if( null != bundle )
            {
                _errorVo.setError( bundle.getInt( KEY_NAME_STATUS_CODE ) ,
                                  bundle.getString( KEY_NAME_ERROR_STRING ) );
                _errorVo.setExtraString( bundle.getString( KEY_NAME_IAP_UPGRADE_URL ) );
            }
        }
        catch( RemoteException e )
        {
            e.printStackTrace();
        }
    }
     
    

    
    
    /* ########################################################################
     * ########################################################################
     * 3. Method using IAP APIs.
     *    ( getItemList, ItemPurchase, getInbox )
     * ########################################################################
     * ##################################################################### */
    
   
    ///////////////////////////////////////////////////////////////////////////
    // 3.1) GetItemListTask ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
   
    /**
     * <PRE>
     * This load item list by starting ItemActivity in this library,
     * and the result will be sent to {@link OnGetItemListener} Callback interface.
     * To do that, {@link ItemActivity} must be described in AndroidManifest.xml of third-party application
     * as below.
     * 
     * &lt;activity android:name="com.sec.android.iap.lib.activity.ItemActivity"
     *      android:theme="@style/Theme.Empty"
     *      android:configChanges="orientation|screenSize"/&gt;
     * </PRE>
     * 
     * @param _itemGroupId 
     * @param _startNum
     * @param _endNum
     * @param _itemType
     * @param _mode
     * @param _onGetItemListener
     */
    public void getItemList
    (   
        String            _itemGroupId,
        int               _startNum,
        int               _endNum,
        String            _itemType,
        int               _mode,
        OnGetItemListener _onGetItemListener
    ) 
    {
        try
        {
            if( null == _onGetItemListener )
            {
                throw new Exception( "OnGetItemListener is null" );
            }
            
            setOnGetItemListener( _onGetItemListener );
            
            Intent intent = new Intent( mContext, ItemActivity.class );
            intent.putExtra( "ItemGroupId", _itemGroupId );
            intent.putExtra( "StartNum", _startNum );
            intent.putExtra( "EndNum", _endNum );
            intent.putExtra( "ItemType", _itemType );
            intent.putExtra( "IapMode", _mode );
            
            intent.setFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
    
            mContext.startActivity( intent );
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
    
    /**
     * execute GetItemListTask
     */
    public void safeGetItemList
    (   
        BaseActivity    _activity,
        String          _itemGroupId,
        int             _startNum,
        int             _endNum,
        String          _itemType
    )
    {
        try
        {
            if( mGetItemListTask != null &&
                mGetItemListTask.getStatus() != Status.FINISHED )
            {
                mGetItemListTask.cancel( true );
            }

            mGetItemListTask = new GetItemListTask( _activity,
                                                    _itemGroupId,
                                                    _startNum,
                                                    _endNum,
                                                    _itemType );
            mGetItemListTask.execute();
        }
        catch( Exception e )
        {
            if( null != _activity )
            {
                _activity.finish();
            }
            
            e.printStackTrace();
        }
    }

    /**
     * Asynchronized Task to load a list of items
     */
    private class GetItemListTask extends AsyncTask<String, Object, Boolean>
    {
        private String            mItemGroupId      = "";
        private int               mStartNum         = 1;
        private int               mEndNum           = 15;
        private String            mItemType         = "";
        
        private BaseActivity      mActivity         = null;

        ErrorVo           mErrorVo   = new ErrorVo();
        ArrayList<ItemVo> mItemList  = new ArrayList<ItemVo>();
        
        public GetItemListTask
        (
            BaseActivity    _activity,
            String          _itemGroupId,
            int             _startNum,
            int              _endNum,
            String          _itemType
        )
        {
            mActivity    = _activity;
            mItemGroupId = _itemGroupId;
            mStartNum    = _startNum;
            mEndNum      = _endNum;
            mItemType    = _itemType;
            
            mActivity.setErrorVo( mErrorVo );
            mActivity.setItemList( mItemList );
        }
        
        @Override
        protected Boolean doInBackground( String... params )
        {
            try
            {
                // 1) call getItemList() method of IAPService
                // ============================================================
                Bundle bundle = getItemList( mItemGroupId,
                                             mStartNum,
                                             mEndNum,
                                             mItemType );
                // ============================================================
                
                // 2) save status code, error string and extra String.
                // ============================================================
                mErrorVo.setError( bundle.getInt( KEY_NAME_STATUS_CODE ),
                                   bundle.getString( KEY_NAME_ERROR_STRING ) );
                
                mErrorVo.setExtraString( bundle.getString( 
                                                  KEY_NAME_IAP_UPGRADE_URL ) );
                // ============================================================
                
                // 3) If item list is loaded successfully,
                //    make item list by Bundle data
                // ============================================================
                if( mErrorVo.getErrorCode() == IAP_ERROR_NONE )
                {
                    ArrayList<String> itemStringList = 
                             bundle.getStringArrayList( KEY_NAME_RESULT_LIST );
                    
                    if( itemStringList != null )
                    {
                        for( String itemString : itemStringList )
                        {
                            ItemVo itemVo = new ItemVo( itemString );
                            mItemList.add( itemVo );
                        }
                    }
                    else
                    {
                        Log.d( TAG, "Bundle Value 'RESULT_LIST' is null." );
                    }
                }
                // ============================================================
                // 4) If failed, print log.
                // ============================================================
                else
                {
                    Log.d( TAG, mErrorVo.getErrorString() );
                }
                // ============================================================
            }
            catch( Exception e )
            {
                mErrorVo.setError(
                        IAP_ERROR_COMMON,
                        mActivity.getString( 
                             R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED ) );
                
                e.printStackTrace();
                return false;
            }
            
            return true;
        }

        @Override
        protected void onPostExecute( Boolean _result )
        {
            // 1. If result is true
            // ================================================================
            if( true == _result )
            {
                // 1) If list of product is successfully loaded
                // ============================================================
                if( mErrorVo.getErrorCode() == IAP_ERROR_NONE )
                {
                    // finish Activity in order to notify the result to
                    // third-party application immediately.
                    // --------------------------------------------------------
                    if( mActivity != null )
                    {
                        mActivity.finish();
                    }
                    // --------------------------------------------------------
                }
                // ============================================================
                // 2) If the IAP package needs to be upgraded
                // ============================================================
                else if( mErrorVo.getErrorCode() == IAP_ERROR_NEED_APP_UPGRADE )
                {
                    // a) When user click the OK button on the dialog,
                    //    go to SamsungApps IAP Detail page.
                    // --------------------------------------------------------
                    Runnable OkBtnRunnable = new Runnable()
                    {
                        @Override
                        public void run()
                        {
                            if( true == TextUtils.isEmpty( 
                                                  mErrorVo.getExtraString() ) )
                            {
                                return;
                            }
                            
                            Intent intent = new Intent(Intent.ACTION_VIEW);
                            
                            intent.setData( 
                                      Uri.parse( mErrorVo.getExtraString() ) );
                            
                            intent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK );

                            try
                            {
                                mActivity.startActivity( intent );
                            }
                            catch( ActivityNotFoundException e )
                            {
                                e.printStackTrace();
                            }
                        }
                    };
                    // --------------------------------------------------------
                    
                    // b) Pop-up shows that the IAP package needs to be updated.
                    // --------------------------------------------------------
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                                   mErrorVo.getErrorString(),
                                   true,
                                   OkBtnRunnable );
                    // --------------------------------------------------------
                
                    Log.e( TAG, mErrorVo.getErrorString() );
                }
                // ============================================================
                // 3) If error is occurred during loading list of product
                // ============================================================
                else
                {
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                                   mErrorVo.getErrorString(), 
                                   true,
                                   null );
                
                    Log.e( TAG, mErrorVo.getErrorString() );
                }
                // ============================================================
            }
            // ================================================================
            // 2. If result is false
            // ================================================================
            else
            {
                showIapDialog( mActivity,
                               mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                               mActivity.getString( R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED )
                                   + "[Lib_ItemList]",
                               true,
                               null );
            }
            // ================================================================
        }
    }
    
    /**
     * Register {@link OnGetItemListener} callback interface to be invoked
     * when {@link GetItemListTask} has been finished.
     * @param _onGetItemListener
     */
    public void setOnGetItemListener( OnGetItemListener _onGetItemListener )
    {
        mOnGetItemListener = _onGetItemListener;
    }
    
    public OnGetItemListener getOnGetItemListener( )
    {
        return mOnGetItemListener;
    }

    /**
     * calling getItemList() to load item list in IAPConnector
     * 
     * @param _itemGroupId
     * @param _startNum
     * @param _endNum
     * @param _itemType
     * @return Bundle
     */
    public Bundle getItemList
    (   
        String  _itemGroupId,
        int     _startNum,
        int     _endNum,
        String  _itemType
    )
    {
        Bundle itemList = null;
        
        try
        {
            itemList = mIapConnector.getItemList( mMode,
                                                  mContext.getPackageName(),
                                                  _itemGroupId,
                                                  _startNum,
                                                  _endNum,
                                                  _itemType );
        }
        catch( RemoteException e )
        {
            e.printStackTrace();
        }

        return itemList;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // 3.2) startPurchase / ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    
    /**
     * <PRE>
     * Start payment process by starting {@link PaymentActivity} in this library,
     * and result will be sent to {@link OnPaymentListener} interface.
     * To do that, PaymentActivity must be described in AndroidManifest.xml of third-party application
     * as below.
     * 
     * &lt;activity android:name="com.sec.android.iap.lib.activity.PaymentActivity"
     *      android:theme="@style/Theme.Empty"
     *      android:configChanges="orientation|screenSize"/&gt;
     * </PRE>
     * 
     * @param _itemGroupId
     * @param _itemId
     * @param _showSuccessDialog  If it is true, dialog of payment success is
     *                            shown. otherwise it will not be shown.
     * @param _onPaymentListener
     * @throws Exception 
     */
    public void startPayment
    (
        String              _itemGroupId,
        String              _itemId,
        boolean             _showSuccessDialog,
        OnPaymentListener   _onPaymentListener
    )
    {
        try
        {
            if( null == _onPaymentListener )
            {
                throw new Exception( "OnPaymentListener is null" );
            }
            
            setOnPaymentListener( _onPaymentListener );
            
            Intent intent = new Intent( mContext, PaymentActivity.class );
            intent.putExtra( "ItemGroupId", _itemGroupId );
            intent.putExtra( "ItemId", _itemId );
            intent.putExtra( "ShowSuccessDialog", _showSuccessDialog );
            intent.putExtra( "IapMode", mMode );
            
            intent.setFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
    
            mContext.startActivity( intent );
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
    
    /**
     * Start payment. 
     * @param _activity
     * @param _requestCode
     * @param _itemGroupId
     * @param _itemId
     */
    public void startPaymentActivity
    (   
        Activity  _activity,
        int       _requestCode,
        String    _itemGroupId,
        String    _itemId
    )
    {
        try
        {
            Bundle bundle = new Bundle();
            bundle.putString( KEY_NAME_THIRD_PARTY_NAME,
                              mContext.getPackageName() );
            
            bundle.putString( KEY_NAME_ITEM_GROUP_ID, _itemGroupId );
            
            bundle.putString( KEY_NAME_ITEM_ID, _itemId );
            
            ComponentName com = new ComponentName( "com.sec.android.iap", 
                    "com.sec.android.iap.activity.PaymentMethodListActivity" );

            Intent intent = new Intent( Intent.ACTION_MAIN );
            intent.addCategory( Intent.CATEGORY_LAUNCHER );
            intent.setComponent( com );

            intent.putExtras( bundle );

            _activity.startActivityForResult( intent, _requestCode );
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
    
    /**
     * Register a callback interface to be invoked
     * when Purchase Process has been finished.
     * @param _onPaymentListener
     */
    public void setOnPaymentListener( OnPaymentListener _onPaymentListener )
    {
        mOnPaymentListener = _onPaymentListener;
    }
    
    public OnPaymentListener getOnPaymentListener()
    {
        return mOnPaymentListener;
    }
        
    ///////////////////////////////////////////////////////////////////////////
    // 3.3) GetInBoxList  / ///////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    
    /**
     * <PRE>
     * Loading inbox list( or list of purchased item ) by starting {@link InboxActivity}
     * in this library, and the result will be sent to
     * {@link OnGetInboxListener} interface. To do that, InboxActivity must be described in
     * AndroidManifest.xml of third-party application as below.
     * 
     * &lt;activity android:name="com.sec.android.iap.lib.activity.InboxActivity"
     *      android:theme="@style/Theme.Empty"
     *      android:configChanges="orientation|screenSize"/&gt;
     * </PRE>
     * 
     * @param _itemGroupId
     * @param _startNum
     * @param _endNum
     * @param _startDate
     * @param _endDate
     * @param _onGetInboxListener
     * @throws Exception 
     */
    public void getItemInboxList
    (   
        String             _itemGroupId,
        int                _startNum,
        int                _endNum,
        String             _startDate,
        String             _endDate,
        OnGetInboxListener _onGetInboxListener
    ) 
    {
        try
        {
            if( null == _onGetInboxListener )
            {
                throw new Exception( "OnGetInboxListener is null" );
            }
            
            setOnGetInboxListener( _onGetInboxListener );
            
            Intent intent = new Intent( mContext, InboxActivity.class );
            intent.putExtra( "ItemGroupId", _itemGroupId );
            intent.putExtra( "IapMode", mMode );
            intent.putExtra( "StartNum", _startNum );
            intent.putExtra( "EndNum", _endNum );
            intent.putExtra( "StartDate", _startDate );
            intent.putExtra( "EndDate", _endDate );
            
            intent.setFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
    
            mContext.startActivity( intent );
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
    
    /**
     * execute GetItemInboxTask
     */
    public void safeGetItemInboxTask
    (
        BaseActivity    _activity,
        String          _itemGroupId,
        int             _startNum,
        int             _endNum,
        String          _startDate,
        String          _endDate
    )
    {
        try
        {
            if( mGetInboxListTask != null &&
                mGetInboxListTask.getStatus() != Status.FINISHED )
            {
                mGetInboxListTask.cancel( true );
            }

            mGetInboxListTask = new GetInboxListTask( _activity,
                                                      _itemGroupId,
                                                      _startNum,
                                                      _endNum,
                                                      _startDate,
                                                      _endDate );
            mGetInboxListTask.execute();
        }
        catch( Exception e )
        {
            if( null != _activity )
            {
                _activity.finish();
            }
            
            e.printStackTrace();
        }
    }
    
    /**
     * AsyncTask to load a list of purchased items
     */
    private class GetInboxListTask extends AsyncTask<String, Object, Boolean>
    {
        private BaseActivity        mActivity           = null;
        private String              mItemGroupId        = "";
        private int                 mStartNum           = 0;
        private int                 mEndNum             = 0;
        private String              mStartDate          = "";
        private String              mEndDate            = "";
        
        private ErrorVo             mErrorVo        = new ErrorVo();
        private ArrayList<InboxVo>  mInbox          = new ArrayList<InboxVo>();
        
        public GetInboxListTask
        (   
            BaseActivity    _activity,
            String          _itemGroupId,
            int             _startNum,
            int             _endNum,
            String          _startDate,
            String          _endDate
        )
        {
            mActivity    = _activity;
            mItemGroupId = _itemGroupId;
            mStartNum    = _startNum;
            mEndNum      = _endNum;
            mStartDate   = _startDate;
            mEndDate     = _endDate;
            
            mActivity.setErrorVo( mErrorVo );
            mActivity.setInbox( mInbox );
        }

        @Override
        protected Boolean doInBackground( String... params )
        {
            try
            {
                // 1. Call getItemsInbox() method of IAPService
                // ============================================================
                Bundle bundle = getItemsInbox( mItemGroupId,
                                               mStartNum,
                                               mEndNum,
                                               mStartDate,
                                               mEndDate );
                // ============================================================
                
                // 2. save status code, error string
                // ============================================================
                mErrorVo.setError( bundle.getInt( KEY_NAME_STATUS_CODE ),
                                   bundle.getString( KEY_NAME_ERROR_STRING ) );
                // ============================================================

                // 3. If inbox(list of purchased item) is loaded successfully,
                //    make inbox by Bundle data
                // ============================================================
                if( IAP_ERROR_NONE == mErrorVo.getErrorCode() )
                {
                    ArrayList<String> purchaseItemStringList = 
                             bundle.getStringArrayList( KEY_NAME_RESULT_LIST );
                
                    if( purchaseItemStringList != null )
                    {
                        for( String itemString : purchaseItemStringList )
                        {
                            InboxVo inboxVo = new InboxVo( itemString );
                            mInbox.add( inboxVo );
                        }
                    }
                    else
                    {
                        Log.d( TAG, "Bundle Value 'RESULT_LIST' is null." );
                    }
                }
                // ============================================================
                // 4. If error occurred, print log.
                // ============================================================
                else
                {
                    Log.d( TAG, mErrorVo.getErrorString() );
                }
                // ============================================================
            }
            catch( Exception e )
            {
                mErrorVo.setError(
                        IAP_ERROR_COMMON,
                        mActivity.getString( 
                             R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED ) );

                e.printStackTrace();
                return false;
            }
            
            return true;
        }

        @Override
        protected void onPostExecute( Boolean _result )
        {
            // 1. result is true
            // ================================================================
            if( true == _result )
            {
                // 1) If inbox(list of purchased item) is successfully loaded
                // ============================================================
                if( mErrorVo.getErrorCode() == IAP_ERROR_NONE )
                {
                    // finish Activity in order to notify the result to
                    // third-party application immediately.
                    // --------------------------------------------------------
                    if( null != mActivity )
                    {
                        mActivity.finish();
                    }
                    // --------------------------------------------------------
                }
                // ============================================================
                // 2) If error is occurred during loading inbox
                // ============================================================ 
                else
                {
                    // show error dialog
                    // --------------------------------------------------------
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                                   mErrorVo.getErrorString(), 
                                   true,
                                   null );
                    // --------------------------------------------------------
                }
                // ============================================================
            }
            // 2. result is false
            // ================================================================
            else
            {
                // show error dialog.
                // ------------------------------------------------------------
                showIapDialog( mActivity,
                               mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                               mActivity.getString( R.string.IDS_SAPPS_POP_UNKNOWN_ERROR_OCCURRED )
                                   + "[Lib_InboxList]", 
                               true,
                               null );
                // ------------------------------------------------------------
            }
            // ================================================================
        }
    }
    
    /**
     * Register a {@link OnGetInboxListener} callback to be invoked
     * when {@link GetInboxListTask} has been finished.
     * @param _onGetInboxListener
     */
    public void setOnGetInboxListener( OnGetInboxListener _onGetInboxListener )
    {
        mOnGetInboxListener = _onGetInboxListener;
    }
    
    public OnGetInboxListener getOnGetInboxListener( )
    {
        return mOnGetInboxListener;
    }
    
    /**
     * call getItemsInbox() method in IAPConnector to load
     * inbox(list of purchased item)
     * 
     * @param _itemGroupId  String
     * @param _startNum     int
     * @param _endNum       int
     * @param _startDate    String "yyyyMMdd" format
     * @param _endDate      String "yyyyMMdd" format
     * @return Bundle
     */
    public Bundle getItemsInbox
    (   
        String  _itemGroupId,
        int     _startNum,
        int     _endNum,
        String  _startDate,
        String  _endDate
    )
    {
        Bundle purchaseItemList = null;
        
        try
        {
            purchaseItemList = mIapConnector.getItemsInbox(
                                                     mContext.getPackageName(),
                                                     _itemGroupId,
                                                     _startNum, 
                                                     _endNum,
                                                     _startDate,
                                                     _endDate );
        }
        catch( RemoteException e )
        {
            e.printStackTrace();
        }

        return purchaseItemList;
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // 3.4) VerifyClientToServer  /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    
    /**
     * Execute {@link VerifyClientToServer}
     * @param _activity
     * @param _purchaseVO
     */
    public void verifyPurchaseResult
    (   
        BaseActivity    _activity,
        PurchaseVo      _purchaseVO,
        boolean         _showSuccessDialog
    )
    {
        try
        {
            if( mVerifyClientToServer != null &&
                mVerifyClientToServer.getStatus() != Status.FINISHED )
            {
                mVerifyClientToServer.cancel( true );
            }

            mVerifyClientToServer = new VerifyClientToServer( 
                                                          _activity,
                                                          _purchaseVO,
                                                          _showSuccessDialog );
            mVerifyClientToServer.execute();
        }
        catch( Exception e )
        {
            if( null != _activity )
            {
                // Result of payment success is notified to third-party
                // application.
                // ============================================================
                _activity.finish();
                // ============================================================
            }
            
            e.printStackTrace();
        }
    }
    
    /**
     * validate result of purchase.
     * 
     * For more secured transaction,
     * We recommend to verify from your server to IAP server.
     */
    private class VerifyClientToServer  extends AsyncTask<Void, Void, Boolean>
    {
        private PurchaseVo       mPurchaseVO        = null;
        private ErrorVo          mErrorVo           = null;
        private VerificationVo   mVerificationVO    = null;
        private BaseActivity     mActivity          = null;
        private boolean          mShowSuccessDialog = false;
        
        
        public VerifyClientToServer
        (   
            BaseActivity    _activity,
            PurchaseVo      _purchaseVO,
            boolean         _showSuccessDialog
        )
        {
            mActivity          = _activity;
            mPurchaseVO        = _purchaseVO;
            mShowSuccessDialog = _showSuccessDialog;
            
            mErrorVo           = new ErrorVo();
            
            mActivity.setErrorVo( mErrorVo );
            mActivity.setPurchaseVo( mPurchaseVO );
        }
        
        @Override
        protected Boolean doInBackground( Void... params )
        {
            if( null == mPurchaseVO || null == mActivity )
            {
                return false;
            }
            
            try
            {
                StringBuffer strUrl = new StringBuffer();
                strUrl.append( VERIFY_URL );
                strUrl.append( "&purchaseID=" + mPurchaseVO.getPurchaseId() );
                
                int     retryCount  = 0;
                String  strResponse = null;
                
                do
                {
                    strResponse = getHttpGetData( strUrl.toString(),
                                                  10000,
                                                  10000 );
                    
                    retryCount++;
                }
                while( retryCount < 3 &&
                       true == TextUtils.isEmpty( strResponse ) );
                
                if( true != TextUtils.isEmpty( strResponse ) )
                {
                    mVerificationVO = new VerificationVo( strResponse );
                    
                    if( false == "true".equals( mVerificationVO.getStatus() ) )
                    {
                        return false;
                    }
                }
                
                return true;
            }
            catch( Exception e )
            {
                e.printStackTrace();
                return true;
            }
        }

        @Override
        protected void onPostExecute( Boolean result )
        {
            // 1. If verification of payment was succeeded.
            // ================================================================
            if( result == true )
            {
                mErrorVo.setError( 
                     IAP_ERROR_NONE,
                     mActivity.getString( R.string.dlg_msg_payment_success ) );
                
                if( true == mShowSuccessDialog )
                {
                    showIapDialog( mActivity,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ),
                                   mErrorVo.getErrorString(),
                                   true,
                                   null );
                }
                else
                {
                    // Finish Activity in order to notify result to
                    // third-party application immediately.
                    // --------------------------------------------------------
                    if( null != mActivity )
                    {
                        mActivity.finish();
                    }
                    // --------------------------------------------------------
                }
            }
            // ================================================================
            // 2. If verification of payment was failed.
            // ================================================================
            else
            {
                // 1) set ErrorCode and ErrorString in order to notify
                //    to third-party application
                // ------------------------------------------------------------
                mErrorVo.setError( IAP_ERROR_COMMON,
                                   mActivity.getString( R.string.IDS_SAPPS_POP_YOUR_PURCHASE_VIA_SAMSUNG_IN_APP_PURCHASE_IS_INVALID_A_FAKE_APPLICATION_HAS_BEEN_DETECTED_CHECK_THE_APP_MSG ) );
                // ------------------------------------------------------------
                
                // 2) Show error dialog.
                // ------------------------------------------------------------
                showIapDialog( mActivity,
                               mActivity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ),
                               mErrorVo.getErrorString(),
                               true,
                               null );
                // ------------------------------------------------------------
            }
            // ================================================================
        }
        
        private String getHttpGetData
        (
            final String _strUrl,
            final int    _connTimeout,
            final int    _readTimeout
        )
        {
            String                  strResult       = null;
            URLConnection           con             = null;
            HttpURLConnection       httpConnection  = null;
            BufferedInputStream     bis             = null; 
            ByteArrayOutputStream   buffer          = null;
            
            try 
            {
                URL url = new URL( _strUrl );
                con = url.openConnection();
                con.setConnectTimeout(10000);
                con.setReadTimeout(10000);
                
                httpConnection = (HttpURLConnection)con;
                httpConnection.setRequestMethod( "GET" );
                httpConnection.connect();
                  
                int responseCode = httpConnection.getResponseCode();

                if( responseCode == 200 )
                {
                    bis = new BufferedInputStream( httpConnection.getInputStream(),
                                                   4096 );
    
                    buffer = new ByteArrayOutputStream( 4096 );             
            
                    byte [] bData = new byte[ 4096 ];
                    int nRead;
                    
                    while( ( nRead = bis.read( bData, 0, 4096 ) ) != -1 )
                    {
                        buffer.write( bData, 0, nRead );
                    }
                    
                    buffer.flush();
                    
                    strResult = buffer.toString();
                }
            } 
            catch( Exception e ) 
            {
                e.printStackTrace();
            }
            finally
            {
                if( bis != null )
                {
                    try { bis.close(); } catch (Exception e) {}
                }
                
                if( buffer != null )
                {
                    try { buffer.close(); } catch (IOException e) {}
                }
                con = null;
                httpConnection = null;
           }
            
           return strResult;
        }
    }
    
    
    
    
    
    // ########################################################################
    // ########################################################################
    // 4. etc
    // ########################################################################
    // ########################################################################
    
    /**
     * Stop running task, {@link InitIapTask}, {@link GetItemListTask},
     * {@link OnGetInboxListener} or {@link VerifyClientToServer} before dispose().
     */
    private void stopTasksIfNotFinished()
    {
        if( mInitIapTask != null )
        {
            if( mInitIapTask.getStatus() != Status.FINISHED )
            {
                mInitIapTask.cancel( true );
            }
        }
        
        if( mGetItemListTask != null )
        {
            if ( mGetItemListTask.getStatus() != Status.FINISHED )
            {
                mGetItemListTask.cancel( true );
            }
        }
        
        if( mGetInboxListTask != null )
        {
            if( mGetInboxListTask.getStatus() != Status.FINISHED )
            {
                mGetInboxListTask.cancel( true );
            }
        }         
        
        if( mVerifyClientToServer != null )
        {
            if( mVerifyClientToServer.getStatus() != Status.FINISHED )
            {
                mVerifyClientToServer.cancel( true );
            }
        }
    }
    
    public void removeAllListener( )
    {
        mOnGetInboxListener = null;
        mOnGetItemListener = null;
        mOnPaymentListener = null;
    }
    
    /**
     * Unbind from IAPService and release used resources.
     */
    public void dispose()
    {
        stopTasksIfNotFinished();
        
        if( mContext != null && mServiceConn != null )
        {
            mContext.unbindService( mServiceConn );
        }
        
        mState         = STATE_TERM;
        mServiceConn   = null;
        mIapConnector  = null;
    }
    
    
        
    // ########################################################################
    // ########################################################################
    // 5. utilities
    // ########################################################################
    // ########################################################################
    
    /**
     * go to IAP detail page of SamsungApps in order to install IAP package.
     */
    public void installIapPackage( final BaseActivity _activity )
    {
        // 1. When user click the OK button on the dialog,
        //    go to SamsungApps IAP Detail page
        // ====================================================================
        Runnable OkBtnRunnable = new Runnable()
        {
            @Override
            public void run()
            {
                // Link of SamsungApps for IAP install
                // ------------------------------------------------------------
                Uri iapDeepLink = Uri.parse( 
                           "samsungapps://ProductDetail/com.sec.android.iap" );
                // ------------------------------------------------------------
                
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setData( iapDeepLink );

                if( Build.VERSION.SDK_INT >= HONEYCOMB_MR1 )
                {
                    intent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK | 
                                     Intent.FLAG_ACTIVITY_CLEAR_TOP | 
                                     FLAG_INCLUDE_STOPPED_PACKAGES );
                }
                else
                {
                    intent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK | 
                                     Intent.FLAG_ACTIVITY_CLEAR_TOP );
                }

                mContext.startActivity( intent );
            }
        };
        // ====================================================================
        
        // 2. Set error in order to notify result to third-party application.
        // ====================================================================
        ErrorVo errorVo = new ErrorVo();
        _activity.setErrorVo( errorVo );
        
        errorVo.setError( SamsungIapHelper.IAP_PAYMENT_IS_CANCELED,
               _activity.getString(R.string.IDS_SAPPS_POP_PAYMENT_CANCELLED) );
        // ====================================================================
        
        // 3. Show information dialog
        // ====================================================================
        showIapDialog( _activity, 
                       _activity.getString( R.string.IDS_SAPPS_POP_SAMSUNG_IN_APP_PURCHASE ), 
                       _activity.getString( R.string.IDS_SAPPS_POP_TO_PURCHASE_ITEMS_YOU_NEED_TO_INSTALL_SAMSUNG_IN_APP_PURCHASE_INSTALL_Q ), 
                       true, 
                       OkBtnRunnable );
        // ====================================================================
    }
    
    /**
     * Check that IAP package is installed
     * @param _context Context
     * @return If it is true IAP package is installed. otherwise, not installed.
     */
    public boolean isInstalledIapPackage( Context _context )
    {
        PackageManager pm = _context.getPackageManager();
        
        try
        {
            pm.getApplicationInfo( IAP_PACKAGE_NAME,
                                   PackageManager.GET_META_DATA );
            return true;
        }
        catch( NameNotFoundException e )
        {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * check validation of installed IAP package in your device
     * @param _context
     * @return If it is true IAP package is valid. otherwise, is not valid.
     */
    public boolean isValidIapPackage( Context _context )
    {
        boolean result = true;
        
        try
        {
            Signature[] sigs = _context.getPackageManager().getPackageInfo(
                                    IAP_PACKAGE_NAME,
                                    PackageManager.GET_SIGNATURES ).signatures;
            
            if( sigs[0].hashCode() != IAP_SIGNATURE_HASHCODE )
            {
                result = false;
            }
        }
        catch( Exception e )
        {
            e.printStackTrace();
            result = false;
        }
        
        return result;
    }
    
    /**
     * show dialog
     * @param _title
     * @param _message
     */
    public void showIapDialog
    ( 
        final Activity _activity,
        String         _title, 
        String         _message,
        final boolean  _finishActivity,
        final Runnable _onClickRunable 
    )
    {
        AlertDialog.Builder alert = new AlertDialog.Builder( _activity );
        
        alert.setTitle( _title );
        alert.setMessage( _message );
        
        alert.setPositiveButton( android.R.string.ok,
                                          new DialogInterface.OnClickListener()
        {
            @Override
            public void onClick( DialogInterface _dialog, int _which )
            {
                if( null != _onClickRunable )
                {
                    _onClickRunable.run();
                }
                
                _dialog.dismiss();
                
                if( true == _finishActivity )
                {
                    _activity.finish();
                }
            }
        } );
        
        if( true == _finishActivity )
        {
            alert.setOnCancelListener( new DialogInterface.OnCancelListener()
            {
                @Override
                public void onCancel( DialogInterface dialog )
                {
                    _activity.finish();
                }
            });
        }

        try
        {
            alert.show();
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
}