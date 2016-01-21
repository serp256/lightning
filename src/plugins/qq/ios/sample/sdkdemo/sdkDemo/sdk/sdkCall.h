//
//  sdkCall.h
//  sdkDemo
//
//  Created by xiaolongzhang on 13-3-29.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentOAuthObject.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import "sdkDef.h"
#import "FGalleryViewController.h"

@interface sdkCall : NSObject<TencentSessionDelegate, TencentApiInterfaceDelegate, FGalleryViewControllerDelegate, TCAPIRequestDelegate>
+ (sdkCall *)getinstance;
+ (void)resetSDK;

+ (void)showInvalidTokenOrOpenIDMessage;
@property (nonatomic, retain)TencentOAuth *oauth;
@property (nonatomic, retain)NSMutableArray* photos;
@property (nonatomic, retain)NSMutableArray* thumbPhotos;
@end
