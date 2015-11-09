package com.fyber.mediation;

import android.app.Activity;
import com.fyber.mediation.unityads.UnityAdsMediationAdapter;
import com.fyber.utils.FyberLogger;
import java.lang.Object;
import java.lang.String;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public final class MediationAdapterStarter {
  private static final String TAG = "MediationAdapterStarter";

  private static void startApplifier(final Activity activity, final Map<String, Object> configs, final Map<String, MediationAdapter> map) {
    try {
      MediationAdapter adapter = new UnityAdsMediationAdapter();
      FyberLogger.d(TAG, "Starting adapter Applifier with version 1.5.2-r2");
      if (adapter.startAdapter(activity, configs)) {
        FyberLogger.d(TAG, "Adapter Applifier with version 1.5.2-r2 was started successfully");
        map.put("applifier", adapter);
      } else {
        FyberLogger.d(TAG, "Adapter Applifier with version 1.5.2-r2 was not started successfully");
      }
    } catch (Exception e) {
      FyberLogger.e(TAG, "Exception occurred while loading adapter Applifier with version 1.5.2-r2", e);
    }
  }

  public static Map<String, MediationAdapter> startAdapters(final Activity activity, final Map<String, Map<String, Object>> configs) {
    Map<String, MediationAdapter> map = new HashMap<>();
    startApplifier(activity, getConfigs(configs, "Applifier"), map);
    return map;
  }

  public static int getAdaptersCount() {
    return 1;
  }

  private static Map<String, Object> getConfigs(Map<String, Map<String, Object>> configs, String adapter) {
    Map<String, Object> config = configs.get(adapter.toLowerCase());
    if (config == null) {
      config = Collections.emptyMap();
    }
    return config;
  }
}
