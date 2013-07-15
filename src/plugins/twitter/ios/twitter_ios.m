#import <Twitter/TWTweetComposeViewController.h>
#import "LightViewController.h"

void ml_tweet() {
	TWTweetComposeViewController *tweetComposeViewController = [[TWTweetComposeViewController alloc] init];
	[tweetComposeViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
    	[[LightViewController sharedInstance] dismissModalViewControllerAnimated:YES];
  	}];
	[[LightViewController sharedInstance] presentModalViewController:tweetComposeViewController animated:YES];
}