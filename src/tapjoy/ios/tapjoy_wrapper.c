#include "tapjoy_wrapper.h"
#include "TapjoyConnect/TapjoyConnect.h"
#include "TapjoyConnect/TapjoyConnectConstants.h"
#import "../../ios/LightViewController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
	[[LightViewController sharedInstance] dismissModalViewControllerAnimated: YES];
  //[self dismissModalViewControllerAnimated: YES];
}


-(void)loadView {
  self.view = [[UIView alloc] initWithFrame: [UIScreen mainScreen].applicationFrame];
  
    [TapjoyConnect showOffersWithViewController: [LightViewController sharedInstance]];  
  
  if (self.currency) {
    [self.view addSubview: [TapjoyConnect showOffersWithCurrencyID: self.currency withCurrencySelector: self.currencySelectorVisible]];
  } else {
    [self.view addSubview: [TapjoyConnect showOffers]];  
  } 
     
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(tapjoyOffersClosed) name: TJC_VIEW_CLOSED_NOTIFICATION object:nil];
}



@end

/*
 * init
 */
void ml_tapjoy_init(value appid, value skey) {
    CAMLparam2(appid, skey);
    [TapjoyConnect requestTapjoyConnect: STR_CAML2OBJC(appid) secretKey: STR_CAML2OBJC(skey)];
    CAMLreturn0;    
}


/*
 * set user id
 */
void ml_tapjoy_set_user_id(value userid) {
  CAMLparam1(userid);
  [TapjoyConnect setUserID: STR_CAML2OBJC(userid)];
  CAMLreturn0;
}


/*
 * get user id
 */
CAMLprim value ml_tapjoy_get_user_id() {
  CAMLparam0();
  CAMLreturn(caml_copy_string([[TapjoyConnect getUserID] UTF8String]));
}

/*
 * 
 */
void ml_tapjoy_action_complete(value action) {
  CAMLparam1(action);
  [TapjoyConnect actionComplete: STR_CAML2OBJC(action)];
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
  [[LightViewController sharedInstance] presentModalViewController: c animated: YES];

  CAMLreturn0;
}


/*
 * show offers. 
 */
void ml_tapjoy_show_offers_with_currency(value currency, value show_selector) {
  CAMLparam2(currency, show_selector);
  
  TapjoyOffersController * c = [[[TapjoyOffersController alloc] init] autorelease];
  c.modalPresentationStyle = UIModalPresentationFormSheet;
  c.currency = STR_CAML2OBJC(currency);
  c.currencySelectorVisible = Bool_val(show_selector);
  [[LightViewController sharedInstance] presentModalViewController: c animated: YES];  
  
  CAMLreturn0;
}


