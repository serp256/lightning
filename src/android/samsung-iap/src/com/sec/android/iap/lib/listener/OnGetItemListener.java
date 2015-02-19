package com.sec.android.iap.lib.listener;

import java.util.ArrayList;

import com.sec.android.iap.lib.helper.SamsungIapHelper;
import com.sec.android.iap.lib.vo.ErrorVo;
import com.sec.android.iap.lib.vo.ItemVo;

/**
 * Callback Interface used with
 * {@link SamsungIapHelper.GetItemListTask}
 */
public interface OnGetItemListener
{
    /**
     * Callback method to be invoked 
     * when {@link SamsungIapHelper.GetItemListTask} has been finished. 
     */
    void onGetItem( ErrorVo _errorVO, ArrayList<ItemVo> _itemList );
}
