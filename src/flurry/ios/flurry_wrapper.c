#include "flurry_wrapper.h"
#include "FlurryAnalytics/FlurryAnalytics.h"
#import <Foundation/Foundation.h>


void ml_flurry_start_session(value ml_appkey) {
  CAMLparam1(ml_appkey);
//  [FlurryAnalytics setShowErrorInLogEnabled: YES];
//  [FlurryAnalytics setDebugLogEnabled:YES];
  [FlurryAnalytics startSession:STR_CAML2OBJC(ml_appkey)];
  CAMLreturn0;
}


void ml_flurry_log_event(value ml_evname, value ml_evtimed, value ml_evparams_opt) {
  CAMLparam3(ml_evname, ml_evtimed, ml_evparams_opt);
  NSMutableDictionary * params = nil;

  if (Is_block(ml_evparams_opt)) {
    value ml_list_item, ml_param;
    ml_list_item = Field(ml_evparams_opt, 0);
    if (Is_block(ml_list_item)) {
      params = [NSMutableDictionary dictionaryWithCapacity: 1];
      while (Is_block(ml_list_item)) {
        ml_param = Field(ml_list_item, 0);
        ml_list_item = Field(ml_list_item, 1);
        [params setValue:STR_CAML2OBJC(Field(ml_param,1))  forKey: STR_CAML2OBJC(Field(ml_param,0))];
      }
    }
  }
  
  [FlurryAnalytics logEvent: STR_CAML2OBJC(ml_evname) withParameters: params timed: Bool_val(ml_evtimed)];
  CAMLreturn0;
}


void ml_flurry_end_timed_event(value ml_evname, value ml_evparams_opt) {
  CAMLparam2(ml_evname, ml_evparams_opt);
  NSMutableDictionary * params = nil;

  if (Is_block(ml_evparams_opt)) {
    params = [NSMutableDictionary dictionaryWithCapacity: 1];
    value ml_list_item, ml_param;
    ml_list_item = Field(ml_evparams_opt, 0);
    while (Is_block(ml_list_item)) {
      ml_param = Field(ml_list_item, 0);
      ml_list_item = Field(ml_list_item, 1);
      [params setValue:STR_CAML2OBJC(Field(ml_param,1))  forKey: STR_CAML2OBJC(Field(ml_param,0))];
    }
  }
    
  [FlurryAnalytics endTimedEvent:STR_CAML2OBJC(ml_evname) withParameters: params];
  CAMLreturn0;
}


void ml_flurry_set_user_id (value ml_uid) {
  CAMLparam1(ml_uid);
  [FlurryAnalytics setUserID:STR_CAML2OBJC(ml_uid)];
  CAMLreturn0;
}


void ml_flurry_set_user_age(value ml_age) {
  CAMLparam1(ml_age);
  [FlurryAnalytics setAge: Int_val(ml_age)];
  CAMLreturn0;
}


void ml_set_user_gender(value ml_gender) {
  CAMLparam1(ml_gender);
  NSString * gender = Int_val(ml_gender) == 0 ? @"m" : @"f";
  NSLog(@"Got gender %@(%d)", gender, Int_val(ml_gender));
  [FlurryAnalytics setGender: gender];
  CAMLreturn0;
}



