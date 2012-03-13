//
//  VKAuthController.h
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VKAuth : UIViewController <UIWebViewDelegate> {
    NSString * _appid;
    UIWebView * _webview;
    UIImageView * _captchaView;
    NSString * _captchaSid;
}

-(id)initWithAppid: (NSString *)appid;
-(void)authorize: (NSString *)permissions;
-(void)displayCaptchaWithSid: (NSString *)captcha_sid andUrl: (NSURL *)captcha_url;
@end
