//
//  main.m
//  LightTest
//
//  Created by Sergey Plaksin on 2/17/12.
//  Copyright (c) 2012 RedSpell. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LightAppDelegate;

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil,NSStringFromClass([LightAppDelegate class]));
	[pool release];
	return retVal;
}
