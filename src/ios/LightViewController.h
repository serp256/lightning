//
//  LightViewController.h
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <StoreKit/StoreKit.h>
#import <caml/mlvalues.h>
#import "LightActivityIndicator.h"

@protocol OrientationDelegate 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
@end

@interface LightViewController : UIViewController <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate, SKPaymentTransactionObserver> {
	id<OrientationDelegate> _orientationDelegate;
	LightActivityIndicatorView*	activityIndicator;
@public
	value payment_success_cb;
	value payment_error_cb;
	value remote_notification_request_success_cb;
	value remote_notification_request_error_cb;
}

+(LightViewController*)sharedInstance;
-(void)stop;
-(void)start;
-(void)showLeaderboard;
-(void)showAchievements;
-(void)showActivityIndicator:(LightActivityIndicatorView *)indicator;
-(void)hideActivityIndicator;

@property (nonatomic,retain) id<OrientationDelegate> orientationDelegate;

@end
