package com.sec.android.iap.lib.listener;

import java.util.ArrayList;

import com.sec.android.iap.lib.helper.SamsungIapHelper;
import com.sec.android.iap.lib.vo.ErrorVo;
import com.sec.android.iap.lib.vo.InboxVo;

/**
 * Callback Interface used with
 * {@link SamsungIapHelper.GetInboxListTask}
 */
public interface OnGetInboxListener
{
    /**
     * Callback method to be invoked 
     * when {@link SamsungIapHelper.GetInboxListTask} has been finished. 
     */
    void onGetItemInbox( ErrorVo _errorVO, ArrayList<InboxVo> _inboxList );
}
