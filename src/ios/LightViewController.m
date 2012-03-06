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


+alloc {
	NSLog(@"Try INIT Light view controller");
	if (instance != NULL) return NULL; // raise exception
	NSLog(@"INIT Light view controller");
	char *argv[] = {"ios",NULL};
	caml_startup(argv);
	instance = [super alloc];
	return instance;
}

-(id)init {
  self = [super init];
  if (self != nil) {
	payment_success_cb = Val_int(1);
	payment_error_cb   = Val_int(1);
	remote_notification_request_success_cb = Val_int(1);
	remote_notification_request_error_cb   = Val_int(1);
  }
  return self;
}

+(LightViewController*)sharedInstance {
	if (!instance) [[LightViewController alloc] init];
	return instance;
}


#pragma mark - View lifecycle
- (void)loadView {
	UIInterfaceOrientation orient = self.interfaceOrientation;
	CGRect rect = [UIScreen mainScreen].applicationFrame;
	switch (orient) {
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight: {
			float tmp = rect.size.width;
			rect.size.width = rect.size.height;
			rect.size.height = tmp;
			break;
	  }
		default: break;
	};
	LightView * lightView = [[LightView alloc] initWithFrame:rect];
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



////////////////////
//// URLConnection

static value *ml_url_response = NULL;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	NSLog(@"did recieve response %lld",response.expectedContentLength);
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


//
-(void)showActivityIndicator: (LightActivityIndicatorView *)indicator {
    if (indicator == nil) {
        indicator = [[[LightActivityIndicatorView alloc] initWithTitle: nil message: @"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
    }

	if (activityIndicator) {
		[activityIndicator dismissWithClickedButtonIndex:-1 animated:YES];
		[activityIndicator release];
	}
	
	activityIndicator = [indicator retain];
    [activityIndicator show];
}


//
-(void)hideActivityIndicator {
	if (!activityIndicator) {
		return;
	}
	[activityIndicator dismissWithClickedButtonIndex:-1 animated:YES];
	[activityIndicator release];
	activityIndicator = nil;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	if (_orientationDelegate) {
		BOOL res = [_orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
		return res;
	}
	else
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



/* handle payment transactions */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BOOL restored;
    LightActivityIndicatorView * indicator;
    for (SKPaymentTransaction *transaction in transactions) {
        restored = NO;
        switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchasing:
				indicator = [[[LightActivityIndicatorView alloc] initWithTitle: nil message:@"Connecting to AppStore" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
				[self showActivityIndicator: indicator];
				break;
            case SKPaymentTransactionStateFailed:
				[self hideActivityIndicator];
				NSString * e;
				if (transaction.error.code != SKErrorPaymentCancelled)
				{
				    e = [transaction.error localizedDescription];
					UIAlertView* alert =
					[
					 [UIAlertView alloc]
					 initWithTitle:@"Payment error"
					 message: e
					 delegate:nil
					 cancelButtonTitle:@"OK"
					 otherButtonTitles:nil
					 ];
					[alert show];
					[alert release];
				} else {
				  e = @"Cancelled";
				}
				
				if (Is_block(payment_error_cb)) {
					caml_acquire_runtime_system();
				  caml_callback3(payment_error_cb, 
				                 caml_copy_string([transaction.payment.productIdentifier cStringUsingEncoding:NSUTF8StringEncoding]), 
				                 caml_copy_string([e cStringUsingEncoding:NSUTF8StringEncoding]), 
				                 Val_bool(transaction.error.code == SKErrorPaymentCancelled));
					caml_release_runtime_system();
				}
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;

            case SKPaymentTransactionStateRestored:
                NSLog(@"Restoring");
                restored = YES;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"Purchased");
				if (Is_block(payment_success_cb)) {
				  
					[transaction retain]; // Обязательно из ocaml надо вызвать commit_transaction!!!

					caml_acquire_runtime_system();
				  caml_callback3(
							payment_success_cb, 
							caml_copy_string([transaction.payment.productIdentifier cStringUsingEncoding:NSUTF8StringEncoding]), // product id
							(value)transaction,
							Val_bool(restored));
							caml_release_runtime_system();
				}
            
				[self hideActivityIndicator];
                break;
            default:
                break;
        }
    }
}

-(void)lightError:(NSString*)error {
	LightView *lightView = (LightView*)self.view;
	[lightView abort];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uncatched error" message:@"MESSAGE" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSUInteger)buttonIndex {
	NSLog(@"alertView clicked button at index: %d",buttonIndex);
	exit(2);
}

@end
