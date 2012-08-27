//
//  LightViewController.m
//  DoodleNumbers
//
//  Created by Yury Lasty on 6/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LightViewController.h"
#import "LightAppDelegate.h"
#import "LightView.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>
#import <caml/fail.h>

@implementation LightViewController

@synthesize orientationDelegate=_orientationDelegate;

static LightViewController *instance = NULL;
static NSString *supportEmail = @"nanofarm@redspell.ru";
UITextField* kbTextField = NULL;
value keyboardCallbackUpdate, keyboardCallbackReturn;

static NSMutableArray *exceptionInfo = nil;

static void mlUncaughtException(const char* exn, int bc, char** bv) {
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *subj = [bundle localizedStringForKey:@"exception_email_subject" value:@"Error report '%@'" table:nil];
  subj = [NSString stringWithFormat:subj, [bundle objectForInfoDictionaryKey: @"CFBundleDisplayName"]];
	UIDevice * dev = [UIDevice currentDevice];
	NSString *appVersion = [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];
	NSString * body = [bundle localizedStringForKey:@"exception_email_body" value:@"" table:nil];
	body = [NSString stringWithFormat:[body stringByAppendingString:@"\n----------------------------------\n"],dev.model, dev.systemVersion, appVersion];
	for (NSString *info in exceptionInfo) {
		body = [body stringByAppendingFormat:@"%@\n",info];
	};
	body = [body stringByAppendingFormat:@"%s\n",exn];
	for (int i = 0; i < bc; i++) {
		if (bv[i]) body = [body stringByAppendingString:[NSString stringWithCString:bv[i] encoding:NSASCIIStringEncoding]];
	};
	NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", supportEmail, subj, body];
  email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

+alloc {
	//NSLog(@"Try INIT Light view controller");
	if (instance != NULL) return NULL; // raise exception
	NSLog(@"INIT Light view controller");
	char *argv[] = {"ios",NULL};
	uncaught_exception_callback = &mlUncaughtException;
	caml_startup(argv);
	caml_release_runtime_system();
	instance = [super alloc];
	return instance;
}

-(id)init {
  self = [super init];
  if (self != nil) {
		payment_success_cb = 0;
		payment_error_cb   = 0;
		remote_notification_request_success_cb = Val_int(1);
		remote_notification_request_error_cb   = Val_int(1);
  }
  return self;
}

+(LightViewController*)sharedInstance {
	if (!instance) [[LightViewController alloc] init];
	return instance;
}

+(void)addExceptionInfo:(NSString*)info {
	if (exceptionInfo == nil) exceptionInfo = [[NSMutableArray alloc] initWithCapacity:1];
	[exceptionInfo addObject:info];
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

-(void)resignActive {
	[(LightView *)(self.view) stop];
}

-(void)becomeActive {
	[(LightView *)(self.view) start];
}

-(void)background {
	[(LightView *)(self.view) background];
}

-(void)foreground {
	[(LightView *)(self.view) foreground];
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
	//NSLog(@"did recieve response %lld",response.expectedContentLength);
	caml_acquire_runtime_system();
	if (ml_url_response == NULL) 
		ml_url_response = caml_named_value("url_response");
	value contentType;
  Begin_roots1(contentType);
	contentType = caml_copy_string([[response MIMEType] cStringUsingEncoding:NSUTF8StringEncoding]);
	value args[4];
	args[0] = (value)connection;
	args[1] = Val_int(response.statusCode);
	args[2] = caml_copy_int64(response.expectedContentLength);
	args[3] = contentType;
	caml_callbackN(*ml_url_response,4,args);
	End_roots();
	caml_release_runtime_system();
}

static value *ml_url_data = NULL;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	//NSLog(@"did revieve data");
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
	//NSLog(@"did fail with error");
	caml_acquire_runtime_system();
	if (ml_url_failed == NULL)
		ml_url_failed = caml_named_value("url_failed");
	NSString *errdesc = [error localizedDescription];
	value errmessage = caml_copy_string([errdesc cStringUsingEncoding:NSUTF8StringEncoding]);
	//NSLog(@"connection didFailWithError with [%s]",String_val(errmessage));
	caml_callback3(*ml_url_failed,(value)connection,Val_int(error.code),errmessage);
	[connection release];
	caml_release_runtime_system();
}


static value *ml_url_complete = NULL;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	//NSLog(@"did finish loading");
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
							//NSLog(@"Restoring");
							restored = YES;
					case SKPaymentTransactionStatePurchased:
							//NSLog(@"Purchased");
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


-(void)didReceiveMemoryWarning {
	NSLog(@"APP did recieve memory warning");
	ml_memoryWarning();
}


- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
  [self resignActive];
  [super presentModalViewController: modalViewController animated: animated];
}


- (void)dismissModalViewControllerAnimated:(BOOL)animated {
	 [super dismissModalViewControllerAnimated: animated];
	 [self becomeActive];
}

+ (void)setSupportEmail:(NSString*)email {
	supportEmail = [email retain];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	caml_callback(keyboardCallbackReturn, caml_copy_string([kbTextField.text UTF8String]));
	[self hideKeyboard];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString * st ;
	if (range.location == 0 && range.length > 0) st = @""; else
	if (range.length > 0 && [kbTextField.text length] > 0)
	{
		NSRange ran;
		ran.location = 0;
		ran.length = range.location ;
		st = [kbTextField.text substringWithRange:ran];
	}
	else
		st = [kbTextField.text stringByAppendingString:string];

	//value str = caml_alloc_string(st.length) ;
	//memcpy(String_val(str),[st UTF8String],st.length);
	//caml_callback(keyboardCallbackUpdate, str);
	//NSLog(@"%s",[textField.text UTF8String]);
	//char * a = (char *) malloc ( st.length + 1 );
	//[st getCString:a maxLength:st.length encoding:NSUTF8StringE   ncoding ];
	caml_callback(keyboardCallbackUpdate, caml_copy_string( [st UTF8String] ));
	// */
	//CAMLlocal1(r);
	//r = caml_copy_string ( [textField.text UTF8String] );
	//caml_callback(keyboardCallbackUpdate, r);
	return YES;
}

- (void)hideKeyboard
{
	if (kbTextField != NULL) 
	{
		caml_remove_global_root(&keyboardCallbackReturn);
		caml_remove_global_root(&keyboardCallbackUpdate);
		keyboardCallbackReturn = 0;
		keyboardCallbackUpdate = 0;
		[kbTextField removeFromSuperview];
		kbTextField = NULL;
	}
}

- (void)showKeyboard:(value)updateCallback returnCallback:(value)returnCallback initString:(value)initString {
	if (keyboardCallbackReturn != 0) caml_remove_global_root(&keyboardCallbackReturn);
	if (keyboardCallbackUpdate != 0) caml_remove_global_root(&keyboardCallbackUpdate);

	if (kbTextField == NULL)
		kbTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 4, 4)];
	[[UIApplication sharedApplication].keyWindow addSubview:kbTextField]; 

	kbTextField.text = [NSString stringWithUTF8String:String_val(initString)];
	[kbTextField setDelegate:self];
	keyboardCallbackReturn = returnCallback;
	keyboardCallbackUpdate = updateCallback;
	caml_register_generational_global_root(&keyboardCallbackReturn);
	caml_register_generational_global_root(&keyboardCallbackUpdate);
	kbTextField.hidden = true;
	kbTextField.autocorrectionType =  UITextAutocorrectionTypeNo;

	[kbTextField becomeFirstResponder]; 
	caml_callback(keyboardCallbackUpdate, caml_copy_string( String_val(initString) ));
}

@end


/*
@implementation LightViewCompatibleController
- (void)dismissModalViewControllerAnimated:(BOOL)animated {
//  [super dismissModalViewControllerAnimated: animated];
  [[LightViewController sharedInstance] dismissModalViewControllerAnimated: animated];
  [[LightViewController sharedInstance] becomeActive];
}  
@end
*/


