//
//  LightViewController.m
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LightViewController.h"
#import "LightView.h"

@implementation LightViewController

@synthesize orientationDelegate=_orientationDelegate;

static LightViewController *instance = NULL;

+(LightViewController*)sharedInstance {
	if (!instance) {
		instance = [[LightViewController alloc] init];
	};
	return instance;
}

#pragma mark - View lifecycle
- (void)loadView {
	LightView * lightView = [[LightView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	[lightView initStage];
	self.view = lightView;
	[lightView release];
}

-(void)stop {
	[(LightView *)(self.view) stop];
}


-(void)start {
	[(LightView *)(self.view) start];
}


-(void)showLeaderboard {
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    if (leaderboardController != nil) {
        leaderboardController.leaderboardDelegate = self;
        [self presentModalViewController: leaderboardController animated: YES];
    }
}


-(void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [self dismissModalViewControllerAnimated:YES];
}


-(void)showAchievements { 
    GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];
    if (achievements != nil){
        achievements.achievementDelegate = self;
        [self presentModalViewController: achievements animated: YES];
    }
    [achievements release];
}


-(void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [self dismissModalViewControllerAnimated:YES];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/


////////////////////
//// URLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
}

// end URL connection
// ////////////////////

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if (_orientationDelegate) return [_orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	else
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
