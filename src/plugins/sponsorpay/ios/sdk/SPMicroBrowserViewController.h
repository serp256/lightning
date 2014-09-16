//
//  SPMicroBrowserViewController.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 22/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPMicroBrowserViewController;

@protocol SPMicroBrowserDelegate <NSObject>

- (void)microBrowserDidClose:(SPMicroBrowserViewController *)browser;

@end

@interface SPMicroBrowserViewController : UIViewController

@property (weak, nonatomic) id<SPMicroBrowserDelegate> delegate;

- (void)loadRequest:(NSURLRequest *)request;

@end
