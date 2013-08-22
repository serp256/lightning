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
#import <caml/memory.h>

#import "twitter_common.h"

void performRequest(TWRequest* req, value v_success, value v_fail) {
	ACAccountStore* accntStore = [[ACAccountStore alloc] init];
	ACAccountType* twitterAccnt = [accntStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

	REG_CALLBACK(success);
	REG_CALLBACK(fail);

	[accntStore requestAccessToAccountsWithType:twitterAccnt withCompletionHandler:^(BOOL granted, NSError *error) {
		NSArray* accnts = [accntStore accountsWithAccountType:twitterAccnt];

		if (granted && [accnts count] > 0) {
			req.account = [accnts objectAtIndex:0];
			[req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
				if (error != nil) {
					if (fail) {
						NSString *err_msg = [[error localizedDescription] retain];
						dispatch_async(dispatch_get_main_queue(),^{
							caml_callback(*fail, caml_copy_string([err_msg UTF8String]));	
							[err_msg release];
							UNREG_CALLBACK(success);
							UNREG_CALLBACK(fail);
						});
					}
				} else {
					NSArray* errs = [[NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil] valueForKey:@"errors"];

					if (errs == nil) {
						if (success) {
							dispatch_async(dispatch_get_main_queue(),^{
								caml_callback(*success, Val_unit);
								UNREG_CALLBACK(success);
								UNREG_CALLBACK(fail);
							});
						}
					} else {
						if (fail) {
							NSDictionary* err = [errs objectAtIndex:0];

							if (err) {
								NSMutableString* mes = [[NSMutableString alloc] initWithCapacity:255];
								[mes appendFormat:@"%@(err code %@)", [err valueForKey:@"message"], [err valueForKey:@"code"]];
								dispatch_async(dispatch_get_main_queue(),^{
									caml_callback(*fail, caml_copy_string([mes UTF8String]));
									[mes release];
									UNREG_CALLBACK(success);
									UNREG_CALLBACK(fail);
								});
							} else {
								dispatch_async(dispatch_get_main_queue(),^{
									caml_callback(*fail, caml_copy_string("unknown error"));
									UNREG_CALLBACK(success);
									UNREG_CALLBACK(fail);
								});
							}
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

value ml_tweet(value v_success, value v_fail, value v_text) {
	CAMLparam3(v_success, v_fail, v_text);

	TWRequest* req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"]
										parameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:String_val(v_text)], @"status", nil]
										requestMethod:TWRequestMethodPOST];
	performRequest(req, v_success, v_fail);

	CAMLreturn(Val_unit);
}

value ml_tweet_pic(value v_success, value v_fail, value v_fname, value v_text) {
	CAMLparam4(v_success, v_fail, v_fname, v_text);

	TWRequest* req = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"]
										parameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:String_val(v_text)], @"status", nil]
										requestMethod:TWRequestMethodPOST];

	NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:String_val(v_fname)] ofType:nil];
	UIImage* img = [UIImage imageWithContentsOfFile:path];
	uint8_t c;
	[[NSData dataWithContentsOfFile:path] getBytes:&c length:1];	

	NSString* imgType;
	NSData* imgData;

	switch (c) {
		case 0xFF:
			imgData = UIImageJPEGRepresentation(img, 1.f);
		    imgType = @"image/jpeg";

		    break;
		case 0x89:
			imgData = UIImagePNGRepresentation(img);
			imgType = @"image/png";

		    break;

		default:
			if (Is_block(v_fail)) {
				caml_callback(Field(v_fail, 0), caml_copy_string("unsupported image type"));
			}

			CAMLreturn(Val_unit);
	}

	[req addMultiPartData:imgData withName:@"media[]" type:imgType];
	performRequest(req, v_success, v_fail);

	CAMLreturn(Val_unit);
}
