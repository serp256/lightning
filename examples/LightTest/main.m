//
//  main.m
//  LightTest
//
//  Created by Sergey Plaksin on 2/3/12.
//  Copyright (c) 2012 RedSpell. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    caml_main(argv);
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
    /*
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }*/
}
