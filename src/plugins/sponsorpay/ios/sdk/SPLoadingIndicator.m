//
//  SPLoadingIndicator.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/12/11.
//  Copyright (c) 2011 SponsorPay. All rights reserved.
//

#import "SPLoadingIndicator.h"
#import "QuartzCore/QuartzCore.h"

static const CGFloat kSPLoadingProgressViewBGColorRed   = .23;
static const CGFloat kSPLoadingProgressViewBGColorBlue  = .23;
static const CGFloat kSPLoadingProgressViewBGColorGreen = .23;
static const CGFloat kSPLoadingProgressViewBGColorAlpha = 1;

static const CGFloat kSPLoadingProgressViewPadding = 15;
static const CGFloat kSPLoadingProgressViewCornerRadius = 10;

static const CGFloat kSPMostTransparentAlphaForFadeAnimation = 0.0;
static const CGFloat kSPMostOpaqueAlpha = 0.95;

static const NSTimeInterval kSPIntroAnimationLength = 0.5;
static const NSTimeInterval kSPOutroAnimationLength = 0.5;

@interface SPLoadingIndicator()

@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) UIView *rootView;
@property (readonly, nonatomic) UIWindow *parentWindow;
@property (assign) BOOL dismissable;

@end

@implementation SPLoadingIndicator

#pragma mark - View hierarchy

@synthesize activityIndicatorView = _activityIndicatorView;

- (UIActivityIndicatorView *)activityIndicatorView
{
    if (!_activityIndicatorView) {
        _activityIndicatorView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activityIndicatorView startAnimating];
    }
    return _activityIndicatorView;
}

@synthesize rootView = _rootView;

- (UIView *)rootView
{
    if (!_rootView) {
        CGSize sizeForRootView = [self sizeForRootView];
        _rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, // Will be centered in window later
                                                             sizeForRootView.width, sizeForRootView.height)];
        
        _rootView.backgroundColor = [UIColor colorWithRed:kSPLoadingProgressViewBGColorRed
                                                    green:kSPLoadingProgressViewBGColorGreen
                                                     blue:kSPLoadingProgressViewBGColorBlue
                                                    alpha:kSPLoadingProgressViewBGColorAlpha];
        _rootView.layer.cornerRadius = kSPLoadingProgressViewCornerRadius;
        
        self.activityIndicatorView.center = _rootView.center;
        
        [_rootView addSubview:self.activityIndicatorView];
    }
    
    return _rootView;
}

@synthesize parentWindow = _parentWindow;

- (UIWindow *)parentWindow {
    if (!_parentWindow) {
        // It's assumed the parent window won't be deallocated during this instance's lifecyle
        _parentWindow = [[UIApplication sharedApplication] keyWindow];
    }
    
    return _parentWindow;
}

- (CGSize)sizeForRootView
{
    CGSize activityIndicatorSize = self.activityIndicatorView.frame.size;
    return CGSizeMake(activityIndicatorSize.width + (2 * kSPLoadingProgressViewPadding),
                      activityIndicatorSize.height + (2 * kSPLoadingProgressViewPadding));
}

#pragma mark - Presenting and dismissing

- (void)presentWithAnimationTypes:(SPAnimationTypes)animationTypes
{
    self.dismissable = YES;

    [self.parentWindow addSubview:self.rootView];
    
    [self setupInitialStateForAnimationTypes:animationTypes];
    
    [UIView animateWithDuration:kSPIntroAnimationLength
                     animations:^{
                         if (animationTypes & SPAnimationTypeFade)
                             self.rootView.alpha = kSPMostOpaqueAlpha;

                         if (animationTypes & SPAnimationTypeTranslateBottomUp)
                            self.rootView.center = self.parentWindow.center;
                     }
     ];
}

- (void)dismiss
{
    if (!self.dismissable) {
        return;
    }
    self.dismissable = NO;
    
    [UIView animateWithDuration:kSPOutroAnimationLength
                     animations:^{
                         self.rootView.alpha = kSPMostTransparentAlphaForFadeAnimation;
                     }
                     completion:^(BOOL finished){
                         [self.rootView removeFromSuperview];
                     }
     ];
}

- (void)setupInitialStateForAnimationTypes:(SPAnimationTypes)animationTypes
{
    CGFloat initialAlpha;
    CGPoint initialCenter;
    
    if (animationTypes & SPAnimationTypeFade) {
         initialAlpha = kSPMostTransparentAlphaForFadeAnimation;
    } else {
        initialAlpha = kSPMostOpaqueAlpha;
    }
    if (animationTypes & SPAnimationTypeTranslateBottomUp) {
        initialCenter.x = self.parentWindow.center.x;
        initialCenter.y = self.parentWindow.frame.size.height;
    } else {
        initialCenter = self.parentWindow.center;
    }
    
    self.rootView.alpha = initialAlpha;
    self.rootView.center = initialCenter;
}

#pragma mark - Housekeeping

- (void)dealloc
{
    self.activityIndicatorView = nil;
    self.rootView = nil;
    
    [super dealloc];
}

@end
