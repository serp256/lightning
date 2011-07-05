//
//  LightViewController.h
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface LightViewController : UIViewController <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>

+(LightViewController*)sharedInstance;
-(void)stop;
-(void)start;
-(void)showLeaderboard;
-(void)showAchievements;

@end
