    //
//  ActivityIndicatorController.m
//  SmartCheat
//
//  Created by Yury Lasty on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LightActivityIndicator.h"



@implementation LightActivityIndicatorView
-(id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    
    self = [super initWithTitle:title message:[NSString stringWithFormat:@"%@\n", message] delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles];
    
    if (self) {
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activity];
        [activity release];
        activity.hidesWhenStopped = NO;
        activity.center = CGPointMake(140, 65);
    }
    return self;
}


-(void)show {
    [super show];
    [activity startAnimating];
}



@end


