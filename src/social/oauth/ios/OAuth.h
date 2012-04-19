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
		NSURL *url;
    NSString * _redirectURIpath;
    UIWebView * _webview;
    UIActivityIndicatorView * _spinner;    
    BOOL _authorizing;
    
    //UIButton * _closeButton;
    UIEdgeInsets _closeButtonInsets;
    NSString * _closeButtonImageName;
    BOOL _closeButtonVisible;    
}


-(OAuth*)initWithURL:(value)mlURL closeButton:(value)mlCloseButton;
//+(OAuth *)sharedInstance;
//-(void)authorize: (NSURL *)url;

//@property (nonatomic, assign)   UIEdgeInsets closeButtonInsets;
//@property (nonatomic, retain)  NSString * closeButtonImageName;
//@property (nonatomic, assign)   BOOL closeButtonVisible;

@end
