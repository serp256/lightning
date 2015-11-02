//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <UIKit/UIKit.h>

@class FYBWebView;
@protocol FYBRewardedVideoWebViewDelegate;

@interface FYBRewardedVideoViewController : UIViewController

@property (nonatomic, weak) id<FYBRewardedVideoWebViewDelegate> rewardedVideoDelegate;

- (id)initWithWebView:(FYBWebView *)webView;


- (void)fadeWebViewIn;

- (void)playVideoFromNetwork:(NSString *)network
                       video:(NSString *)video
                   showAlert:(BOOL)showAlert
                alertMessage:(NSString *)alertMessage
             clickThroughURL:(NSURL *)clickThroughURL;

- (void)showCloseButton;
- (void)hideCloseButton;

@end
