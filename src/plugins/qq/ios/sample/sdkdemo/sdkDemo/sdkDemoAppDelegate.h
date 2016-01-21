//
//  sdkDemoAppDelegate.h
//  sdkDemo
//
//  Created by xiaolongzhang on 13-3-29.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sdkDemoViewController.h"
#import <TencentOpenAPI/TencentApiInterface.h>


@interface sdkDemoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) sdkDemoViewController *viewController;

@end
