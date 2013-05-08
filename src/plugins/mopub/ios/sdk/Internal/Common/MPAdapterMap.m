//
//  MPAdapterMap.m
//  MoPub
//
//  Created by Andrew He on 1/26/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPAdapterMap.h"

@interface MPAdapterMap ()

@property (nonatomic, retain) NSDictionary *bannerAdapterMap;
@property (nonatomic, retain) NSDictionary *interstitialAdapterMap;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdapterMap

@synthesize bannerAdapterMap;
@synthesize interstitialAdapterMap;

+ (id)sharedAdapterMap
{
    static MPAdapterMap *sharedAdapterMap = nil;
	@synchronized(self)
	{
		if (sharedAdapterMap == nil)
			sharedAdapterMap = [[self alloc] init];
	}
	return sharedAdapterMap;
}

- (id)init
{
	if (self = [super init])
	{
        bannerAdapterMap = [[NSDictionary dictionaryWithObjectsAndKeys:
                             @"MPHTMLBannerAdapter",        @"html",
                             @"MPMRAIDBannerAdapter",       @"mraid",
                             @"MPIAdAdapter",               @"iAd",
                             @"MPGoogleAdSenseAdapter",     @"adsense",
                             @"MPGoogleAdMobAdapter",       @"admob_native",
                             @"MPMillennialAdapter",        @"millennial_native",
                             @"MPBannerCustomEventAdapter", @"custom",
                             nil] retain];
        
        interstitialAdapterMap = [[NSDictionary dictionaryWithObjectsAndKeys:
                                   @"MPHTMLInterstitialAdapter",        @"html",
                                   @"MPMRAIDInterstitialAdapter",       @"mraid",
                                   @"MPIAdInterstitialAdapter",         @"iAd_full",
                                   @"MPGoogleAdMobInterstitialAdapter", @"admob_full",
                                   @"MPMillennialInterstitialAdapter",  @"millennial_full",
                                   @"MPInterstitialCustomEventAdapter", @"custom",
                                   nil] retain];
	}
	return self;
}

- (void)dealloc
{
    self.bannerAdapterMap = nil;
	self.interstitialAdapterMap = nil;
	[super dealloc];
}

- (Class)bannerAdapterClassForNetworkType:(NSString *)networkType
{
    return NSClassFromString([self.bannerAdapterMap objectForKey:networkType]);
}

- (Class)interstitialAdapterClassForNetworkType:(NSString *)networkType
{
    return NSClassFromString([self.interstitialAdapterMap objectForKey:networkType]);
}

@end
