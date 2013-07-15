#import <Twitter/TWRequest.h>
#import <Twitter/TWTweetComposeViewController.h>

#import <Accounts/ACAccount.h>
#import <Accounts/ACAccountStore.h>
#import <Accounts/ACAccountType.h>

#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>

#import "LightViewController.h"
#import <caml/callback.h>
#import <caml/alloc.h>

void ml_tweet(value success, value fail, value text) {
	ACAccountStore* accntStore = [[ACAccountStore alloc] init];
	ACAccountType* twitterAccnt = [accntStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

	[accntStore requestAccessToAccountsWithType:twitterAccnt withCompletionHandler:^(BOOL granted, NSError *error) {
		NSArray* accnts = [accntStore accountsWithAccountType:twitterAccnt];

		if (granted && [accnts count] > 0) {
			TWRequest* req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"]
												parameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:String_val(text)], @"status", nil]
												requestMethod:TWRequestMethodPOST];
			req.account = [accnts objectAtIndex:0];
			[req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
				if (error != nil) {
					if (Is_block(fail)) {
						caml_callback(Field(fail,0), caml_copy_string([[error localizedDescription] UTF8String]));	
					}
				} else {
					NSArray* errs = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil] valueForKey:@"errors"];

					if (errs == nil) {
						if (Is_block(success)) {
							caml_callback(Field(success, 0), Val_unit);
						}
					} else {
						if (Is_block(fail)) {
							caml_callback(Field(fail, 0), caml_copy_string([[[errs objectAtIndex:0] valueForKey:@"message"] UTF8String]));
						}
					}
				}

				[accntStore release];
				[req release];				
			}];
		} else {
			UIViewController* tweetComposer;
			LightViewController* lvc = [LightViewController sharedInstance];

			if([SLComposeViewController class] != nil) {
			    tweetComposer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
			    [(SLComposeViewController *)tweetComposer setCompletionHandler:^(SLComposeViewControllerResult result) {
			        [lvc dismissViewControllerAnimated:NO completion:nil];
			    }];
			}
			else {
			    tweetComposer = [[TWTweetComposeViewController alloc] init];

			    [(TWTweetComposeViewController *)tweetComposer setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
			        [lvc dismissViewControllerAnimated:NO completion:nil];
			    }];
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				for (UIView *view in [[tweetComposer view] subviews]) {
					[view removeFromSuperview];
				}

			    [lvc presentViewController:tweetComposer animated:NO completion:nil];
			});
		}
	}];
}