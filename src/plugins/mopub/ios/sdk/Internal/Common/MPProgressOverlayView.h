//
//  MPProgressOverlayView.h
//  MoPub
//
//  Created by Andrew He on 7/18/12.
//  Copyright 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MPProgressOverlayViewDelegate;

@interface MPProgressOverlayView : UIView {
    id<MPProgressOverlayViewDelegate> _delegate;
    UIView *_outerContainer;
    UIView *_innerContainer;
    UIActivityIndicatorView *_activityIndicator;
    UIButton *_closeButton;
    CGPoint _closeButtonPortraitCenter;
}

+ (void)presentOverlayInWindow:(UIWindow *)window animated:(BOOL)animated
                      delegate:(id<MPProgressOverlayViewDelegate>)delegate;
+ (void)dismissOverlayFromWindow:(UIWindow *)window animated:(BOOL)animated;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPProgressOverlayViewDelegate <NSObject>

@optional
- (void)overlayCancelButtonPressed;
- (void)overlayDidAppear;

@end
