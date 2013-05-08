//
//  MPFeatureDetector.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPStoreKitProvider.h"
#import "MPGlobal.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_6_0
#import <StoreKit/StoreKit.h>
#endif

@implementation MPStoreKitProvider

+ (BOOL)deviceHasStoreKit
{
    return !!NSClassFromString(@"SKStoreProductViewController");
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_6_0
+ (SKStoreProductViewController *)buildController
{
    return [[[SKStoreProductViewController alloc] init] autorelease];
}
#endif

@end
