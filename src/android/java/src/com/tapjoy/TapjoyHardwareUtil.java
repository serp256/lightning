// //
//Copyright (C) 2012 by Tapjoy Inc.
//
//This file is part of the Tapjoy SDK.
//
//By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
//The Tapjoy SDK is bound by the Tapjoy SDK License Agreement can be found here: https://www.tapjoy.com/sdk/license


package com.tapjoy;

import java.lang.reflect.Field;


public class TapjoyHardwareUtil
{
	public TapjoyHardwareUtil()
	{
		
	}
	
	
	/**
	 * Gets the serial number of the device.
	 * @return								Serial number of the device, null if unable to otherwise.
	 */
	public String getSerial()
	{
		String serial = null;
		try
		{
			// android.os.Build.SERIAL
			Class<?> clazz = Class.forName("android.os.Build");
			Field field = clazz.getDeclaredField("SERIAL");
			
			if (field.isAccessible() == false)
				field.setAccessible(true);
			
			serial = field.get(android.os.Build.class).toString();
			
			TapjoyLog.i("TapjoyHardwareUtil", "serial: " + serial);
		}
		catch (Exception e)
		{
			TapjoyLog.e("TapjoyHardwareUtil", e.toString());
		}
		
		return serial;
	}
}
