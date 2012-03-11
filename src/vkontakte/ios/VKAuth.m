//
//  VKAuthController.m
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKAuth.h"
#import "../ios/LightViewController.h"
#import <caml/mlvalues.h>                                                                                                                               
#import <caml/callback.h>                                                                                                                               
#import <caml/alloc.h>
#import <caml/threads.h> 

@implementation VKAuth

/* 
 * Initialize
 */
-(id)initWithAppid: (NSString *)appid {
    self = [super initWithFrame: [UIScreen mainScreen].applicationFrame];
        
    if (self != nil) {
        _appid = [appid copy];
        _webview = [[UIWebView alloc] initWithFrame:self.bounds];
        _webview.delegate = self;
        [self addSubview:_webview];
    }
    
    return self;
}


/*
 *  Show auth dialog
 */
-(void)authorize:(NSString *)permissions {

    if (self.superview == nil) {
        [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:self];
        [[LightViewController sharedInstance] resignActive];
    }
    
    
    NSString * urlstr = [NSString stringWithFormat:@"http://oauth.vkontakte.ru/authorize?client_id=%@&scope=%@&redirect=%@&display=touch&response_type=token", 
                         _appid, permissions, [@"http://oauth.vkontakte.ru/blank.html" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlstr]]];
}


/*
 * webview delegate
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[LightViewController sharedInstance] becomeActive];
    [self removeFromSuperview];
    caml_acquire_runtime_system();
    value *mlf = (value*)caml_named_value("vk_login_failed");
    if (mlf != NULL) {                                                                                                                   
      caml_callback(*mlf, Val_int(1));
    }
    caml_release_runtime_system();
}


/*
 *
 */
-(void)webViewDidFinishLoad:(UIWebView *)webView {

    value *mlf;
    
    // промежуточный вызов
    if (![webView.request.URL.path isEqualToString:@"/blank.html"]) {
        return;
    }
    
    NSArray * pairs = [webView.request.URL.fragment componentsSeparatedByString:@"&"];   
    NSString *token, *expires, *user_id;
    token = expires = user_id = nil;
    
    for (NSString * pair in pairs) {
        NSArray * kv = [pair componentsSeparatedByString:@"="];
        if ([[kv objectAtIndex:0] isEqualToString:@"error"]) {
            [[LightViewController sharedInstance] becomeActive];
            [self removeFromSuperview];
            caml_acquire_runtime_system();
            mlf = (value*)caml_named_value("vk_login_failed");
            if (mlf != NULL) {
              caml_callback(*mlf, Val_int(0));
            }
            caml_release_runtime_system();
            return; 
        } else if ([[kv objectAtIndex:0] isEqualToString:@"access_token"]) {
            token = [kv objectAtIndex:1];
        } else if ([[kv objectAtIndex:0] isEqualToString:@"expires_in"]) {
            expires = [kv objectAtIndex:1]; 
        } else if ([[kv objectAtIndex:0] isEqualToString:@"user_id"]) {
            user_id = [kv objectAtIndex:1];
        }
    }
    
    [[LightViewController sharedInstance] becomeActive];
    [self removeFromSuperview];
    caml_acquire_runtime_system();
    mlf = (value*)caml_named_value("vk_logged_in");
    if (mlf != NULL) {
        caml_callback3(*mlf, 
            caml_copy_string([user_id UTF8String]),
            caml_copy_string([token   UTF8String]),
            caml_copy_string([expires UTF8String])
        );
    }
    caml_release_runtime_system();
}


/*
 * Show captcha
 */
-(void)displayCaptchaWithSid: (NSString *)captcha_sid andUrl: (NSURL *)captcha_url {
  _captchaSid = [captcha_sid copy];  
  NSData * imgdata = [NSData dataWithContentsOfURL: captcha_url];
  UIImage * img = [UIImage imageWithData: imgdata];
  _captchaView = [[UIImageView alloc] initWithImage: img];
  [self addSubview: _captchaView];
  
  if (self.superview == nil) {
        [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addSubview:self];
  }
    
  UIAlertView * alert = [[[UIAlertView alloc] initWithTitle: @"Captcha" message: @"Enter text in the picture" delegate:self cancelButtonTitle:nil  otherButtonTitles: @"OK", nil] autorelease];
  [alert show];
}


/* 
 *
 */
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    value * mlf = (value*)caml_named_value("vk_captcha_entered");
    caml_acquire_runtime_system();
    if (mlf != NULL) {
        caml_callback2(*mlf, 
            caml_copy_string([_captchaSid UTF8String]),
            caml_copy_string([@"Hello"  UTF8String])
        );
    }  
    caml_release_runtime_system();
}

@end
