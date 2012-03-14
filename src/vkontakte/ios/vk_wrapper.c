#import "VKAuth.h"
#import "vk_wrapper.h"
#import "../ios/LightViewController.h"

VKAuth * _vk = nil;

void ml_vk_init(value appid) {
  CAMLparam1(appid);
  _vk = [[VKAuth alloc] initWithAppid: STR_CAML2OBJC(appid)];
  CAMLreturn0;
}

void ml_vk_authorize(value permissions) {
  CAMLparam1(permissions);
  [[LightViewController sharedInstance] presentModalViewController: _vk animated: YES];
  [_vk authorize: STR_CAML2OBJC(permissions)];
  CAMLreturn0;
}


void ml_vk_display_captcha(value sid, value url) {
  CAMLparam2(sid, url);
//  [_vk displayCaptchaWithSid: STR_CAML2OBJC(sid) andUrl: [NSURL URLWithString: STR_CAML2OBJC(url)]];
  CAMLreturn0;
}


