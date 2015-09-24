//#import "TapjoyConnectConstants.h"
#import <Tapjoy/Tapjoy.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>


#import "../../ios/LightViewController.h"



#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

@interface TapjoyOffersController : UIViewController {
  NSString * _currency;
  BOOL _selectorVisible;
}
@property (nonatomic, retain) NSString * currency;
@property (nonatomic, assign) BOOL currencySelectorVisible;
@end



@implementation TapjoyOffersController
@synthesize currency = _currency, currencySelectorVisible = _selectorVisible;

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

-(void)tapjoyOffersClosed {
	[[LightViewController sharedInstance] dismissViewControllerAnimated: YES completion:nil];
}


-(void)loadView {
	UIView *view = [[UIView alloc] initWithFrame: [UIScreen mainScreen].applicationFrame];
  
	//[TapjoyConnect showOffersWithViewController: [LightViewController sharedInstance]];  
	//
	view.userInteractionEnabled = YES;
	self.view = view;
  
  if (self.currency) {
    [Tapjoy showOffersWithCurrencyID:self.currency withViewController:self withCurrencySelector:self.currencySelectorVisible];
  } else {
    [Tapjoy showOffersWithViewController:self];
  } 
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(tapjoyOffersClosed) name:TJC_VIEW_CLOSED_NOTIFICATION object:nil];
}

@end

/*
 * init
 */
void ml_tapjoy_init(value appid, value skey) {
    CAMLparam2(appid, skey);
		[Tapjoy enableLogging:YES];
    //[Tapjoy requestTapjoyConnect: STR_CAML2OBJC(appid) secretKey: STR_CAML2OBJC(skey)];
		NSLog (@"key: %@",STR_CAML2OBJC(appid));
  //  [Tapjoy connect: STR_CAML2OBJC(appid)];;



  // NOTE: This is the only step required if you're an advertiser.
  // NOTE: This must be replaced by your App ID. It is retrieved from the Tapjoy website, in your account.
  [Tapjoy connect:STR_CAML2OBJC(appid)
             options:@{ TJC_OPTION_ENABLE_LOGGING : @(YES) }];

    CAMLreturn0;    
}


/*
 * set user id
 */
void ml_tapjoy_set_user_id(value userid) {
  CAMLparam1(userid);
  [Tapjoy setUserID:STR_CAML2OBJC(userid)];
  CAMLreturn0;
}


/*
 * get user id
 */
CAMLprim value ml_tapjoy_get_user_id() {
  CAMLparam0();
  CAMLlocal1(vuid);
  NSString *muid = ((Tapjoy*)[Tapjoy sharedTapjoyConnect]).userID;
  vuid = caml_copy_string([muid UTF8String]);
  CAMLreturn(vuid);
}

/*
 * 
 */
void ml_tapjoy_action_complete(value action) {
  CAMLparam1(action);
  [Tapjoy actionComplete: STR_CAML2OBJC(action)];
  CAMLreturn0;
}

/*
 * show offers. default currency. no currency selector.
 */
void ml_tapjoy_show_offers() {
  CAMLparam0();

  TapjoyOffersController * c = [[[TapjoyOffersController alloc] init] autorelease];
  c.modalPresentationStyle = UIModalPresentationFormSheet;
  c.currency = nil;
  c.currencySelectorVisible = NO;
  [[LightViewController sharedInstance] presentViewController: c animated: YES completion:nil];
	//[TapjoyConnect showOffersWithViewController:[LightViewController sharedInstance]];

  CAMLreturn0;
}


/*
 * show offers. 
 */
void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
  CAMLparam2(currency, show_selector);
  
  TapjoyOffersController * c = [[[TapjoyOffersController alloc] init] autorelease];
  //c.modalPresentationStyle = UIModalPresentationFormSheet;
  c.currency = STR_CAML2OBJC(currency);
  c.currencySelectorVisible = Bool_val(show_selector);
  [[LightViewController sharedInstance] presentViewController: c animated: YES completion:nil];  
  
  CAMLreturn0;
}
