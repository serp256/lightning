//
//  AppDelegate.h
//  LightTest
//
//  Created by Sergey Plaksin on 2/17/12.
//  Copyright (c) 2012 RedSpell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightViewController.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LightViewController *viewController;

@end
