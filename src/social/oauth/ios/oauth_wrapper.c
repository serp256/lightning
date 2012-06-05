#import "OAuth.h"
#import "oauth_wrapper.h"
#import "../../ios/LightViewController.h"

void ml_authorization_grant(value url,value close_button) {
  CAMLparam1(url);
	//fprintf(stderr,"create oauth\n");
  OAuth *oauth = [[OAuth alloc] initWithURL:url closeButton:close_button];
	//fprintf(stderr,"sharedInstace - %p, present: %p\n",[LightViewController sharedInstance],oauth);
	//caml_release_runtime_system();
	[[LightViewController sharedInstance] presentModalViewController:oauth animated:YES];
	[oauth release];
	//caml_acquire_runtime_system();
	//fprintf(stderr,"oauth presented\n");
	/*
  if ([LightViewController sharedInstance].presentedViewController == nil) {
    [[LightViewController sharedInstance] presentModalViewController: oauth animated: YES];
  }
  [oauth authorize: [NSURL URLWithString: STR_CAML2OBJC(url)]];
	*/
  CAMLreturn0;
}


/*
void ml_set_close_button_insets(value top, value left, value bottom, value right) {
  CAMLparam4(top,left,bottom,right);
  OAuth * oauth = [OAuth sharedInstance];
  oauth.closeButtonInsets = UIEdgeInsetsMake(Int_val(top), Int_val(left), Int_val(bottom), Int_val(right));
  CAMLreturn0;
}


void ml_set_close_button_visible(value visible) {
  CAMLparam1(visible);
  OAuth * oauth = [OAuth sharedInstance];
  oauth.closeButtonVisible = Bool_val(visible);  
  CAMLreturn0;
}


void ml_set_close_button_image_name(value name) {
  CAMLparam1(name);
  OAuth * oauth = [OAuth sharedInstance];
  oauth.closeButtonImageName = [NSString stringWithCString:String_val(name) encoding:NSASCIIStringEncoding];
  CAMLreturn0;
}
*/
