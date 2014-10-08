//
//  NanoFarmAppDelegate.m
//  NanoFarm
//
//  Created by Sergey Plaksin on 7/18/11.
//  Copyright 2011 RedSpell. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

/*
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[super application:application didFinishLaunchingWithOptions:launchOptions];
	lightViewController.orientationDelegate = self;
	return YES;
}
*/

-(NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
	return UIInterfaceOrientationMaskAll;
}

/*
-(BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutotaitate from nano delegate");
	return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}
*/

/*-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation from nano delegate");
	return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}

-(NSUInteger)supportedInterfaceOrientations {
	NSLog(@"supportedInterfaceOrientations from nano delegate");
	return UIInterfaceOrientationMaskPortrait;
}*/


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation from light test delegate");
	return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

-(NSUInteger)supportedInterfaceOrientations {
	NSLog(@"supportedInterfaceOrientations from light test delegate");
  return UIInterfaceOrientationMaskLandscape;
}



@end
