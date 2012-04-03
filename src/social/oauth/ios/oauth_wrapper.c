#import "OAuth.h"
#import "oauth_wrapper.h"
#import "../../ios/LightViewController.h"

void ml_authorization_grant(value url) {
  CAMLparam1(url);
  OAuth * oauth = [OAuth sharedInstance];
  if ([LightViewController sharedInstance].presentedViewController == nil) {
    [[LightViewController sharedInstance] presentModalViewController: oauth animated: YES];
  }
  [oauth authorize: [NSURL URLWithString: STR_CAML2OBJC(url)]];
  CAMLreturn0;
}

