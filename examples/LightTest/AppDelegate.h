//
//  AppDelegate.h
//  LightTest
//
//  Created by Sergey Plaksin on 2/3/12.
//  Copyright (c) 2012 RedSpell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    LightViewController *gameController;
}

@property (retain, nonatomic) UIWindow *window;

@end
