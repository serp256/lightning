// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#import "TJCFeaturedAppDBManager.h"
#import "sqlite3.h"
#import "TJCLog.h"
#import "SynthesizeSingleton.h"
#import "TJCFeaturedAppModel.h"

@implementation TJCFeaturedAppDBManager


TJC_SYNTHESIZE_SINGLETON_FOR_CLASS(TJCFeaturedAppDBManager)

- (id)init
{
	self = [super init];

	if (self)
	{
		featuredAdDict_ = [[NSUserDefaults standardUserDefaults] objectForKey:TJC_FEATURED_AD_DICT];
		
		if (!featuredAdDict_)
		{
			featuredAdDict_ = [[NSMutableDictionary alloc] init];
			[[NSUserDefaults standardUserDefaults] setObject:featuredAdDict_ forKey:TJC_FEATURED_AD_DICT];
		}
	}
	return self;
}


- (BOOL)addApp:(TJCFeaturedAppModel*)anAppObj
{	
	NSNumber *appDisplayCount = [featuredAdDict_ objectForKey:[anAppObj storeID]];
	
	// Only create a new entry if there is no existing display count for the store ID key.
	if (!appDisplayCount)
	{
		[featuredAdDict_ setObject:[NSNumber numberWithInt:1] forKey:[anAppObj storeID]];
		[[NSUserDefaults standardUserDefaults] setObject:featuredAdDict_ forKey:TJC_FEATURED_AD_DICT];
	}
	
	return TRUE;
}


- (BOOL)incrementDisplayedCountForStoreID:(NSString*)aStoreID
{
	int displayCount = [[featuredAdDict_ objectForKey:aStoreID] intValue];
	displayCount++;
	
	[featuredAdDict_ setObject:[NSNumber numberWithInt:displayCount] forKey:aStoreID];
	[[NSUserDefaults standardUserDefaults] setObject:featuredAdDict_ forKey:TJC_FEATURED_AD_DICT];
	
	return TRUE;
}


- (int)getDisplayedCountForStoreID:(NSString*)aStoreID
{	
	NSNumber *displayCount = [featuredAdDict_ objectForKey:aStoreID];
	
	if (!displayCount)
	{
		return 0;
	}
	
	return [displayCount intValue];
}


- (void)dealloc
{
	[featuredAdDict_ release];
	[super dealloc];
}

@end
