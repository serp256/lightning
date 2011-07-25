//
//  LightViewController.m
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LightViewController.h"
#import "LightView.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>

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

static value *ml_url_response = NULL;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	NSLog(@"did revieve response");
	caml_acquire_runtime_system();
	if (ml_url_response == NULL) 
		ml_url_response = caml_named_value("url_response");
	value contentType;
  Begin_roots1(contentType);
	contentType = caml_copy_string([[response MIMEType] cStringUsingEncoding:NSUTF8StringEncoding]);
	value args[4];
	args[0] = (value)connection;
	args[1] = Val_int(response.statusCode);
	args[3] = caml_copy_int64(response.expectedContentLength);
	args[2] = contentType;
	caml_callbackN(*ml_url_response,4,args);
	End_roots();
	caml_release_runtime_system();
}

static value *ml_url_data = NULL;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"did revieve data");
	caml_acquire_runtime_system();
	if (ml_url_data == NULL) 
		ml_url_data = caml_named_value("url_data");
	int size = data.length;
	value mldata = caml_alloc_string(size); memcpy(String_val(mldata),data.bytes,size);
	caml_callback2(*ml_url_data,(value)connection,mldata);
	caml_release_runtime_system();
}

static value *ml_url_failed = NULL;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"did fail with error");
	caml_acquire_runtime_system();
	if (ml_url_failed == NULL)
		ml_url_failed = caml_named_value("url_failed");
	NSString *errdesc = [error localizedDescription];
	value errmessage = caml_copy_string([errdesc cStringUsingEncoding:NSUTF8StringEncoding]);
	NSLog(@"connection didFailWithError with [%s]",String_val(errmessage));
	caml_callback3(*ml_url_failed,(value)connection,Val_int(error.code),errmessage);
	[connection release];
	caml_release_runtime_system();
}


static value *ml_url_complete = NULL;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"did finish loading");
	caml_acquire_runtime_system();
	if (ml_url_complete == NULL)
		ml_url_complete = caml_named_value("url_complete");
	caml_callback(*ml_url_complete,(value)connection);
	[connection release];
	caml_release_runtime_system();
}

// end URL connection
// ////////////////////



-(void)showActivityIndicator:(CGPoint)pos {
	if (!activityIndicator) activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicator.center = pos;
	self.view.userInteractionEnabled = NO;
	[self.view addSubview:activityIndicator];
	[activityIndicator startAnimating];
}

-(void)hideActivityIndicator {
	[activityIndicator stopAnimating];
	[activityIndicator removeFromSuperview];
	self.view.userInteractionEnabled = YES;
}

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
