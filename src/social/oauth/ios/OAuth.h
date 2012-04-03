//
//  VKAuthController.h
//  vktest
//
//  Created by Yury Lasty on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../ios/LightViewController.h"

@interface OAuth : LightViewCompatibleController  <UIWebViewDelegate> {
    UIWebView * _webview;
    NSString * _redirectURIpath;
    UIActivityIndicatorView * _spinner;    
}
+(OAuth *)sharedInstance;
-(void)authorize: (NSURL *)url;
@end
