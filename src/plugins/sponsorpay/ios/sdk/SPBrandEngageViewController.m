//
//  SPBrandEngageViewController.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <os/object.h>

#import "SPBrandEngageViewController.h"
#import "SPBrandEngageWebView.h"
#import "SPSystemVersionChecker.h"
#import "SPVideoPlayerViewController.h"
#import "SPVideoPlayerStateDelegate.h"
#import "SPConstants.h"
#import "SPLogger.h"
#import "NSString+SPURLEncoding.h"

@interface SPBrandEngageViewController () <SPVideoPlaybackStateDelegate>

@property (strong, nonatomic) SPBrandEngageWebView *webView;

@property (strong, nonatomic) SPVideoPlayerViewController *videoViewController;

@property (copy, nonatomic) NSString *tpnName;
@property (copy, nonatomic) NSString *video;

#if OS_OBJECT_HAVE_OBJC_SUPPORT
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
#else
@property (assign, nonatomic) dispatch_semaphore_t semaphore;
#endif


@end

@implementation SPBrandEngageViewController {
    BOOL _viewDidAppearPreviously;
}

#pragma mark - Housekeeping

- (id)initWithWebView:(SPBrandEngageWebView *)webView
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.wantsFullScreenLayout = YES;
        self.webView = webView;
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc
{
    [self.webView setDelegate:nil];
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    if (!self.webView) {
        SPLogError(@"Brand Engage View Controller's Web View is nil!");
        return;
    }

    if (![SPSystemVersionChecker runningOniOS6OrNewer]) // <-- fix targeted to iOS 5
        self.view.frame = [self fullScreenFrameForInterfaceOrientation:self.interfaceOrientation];

    if (!self.webView.superview) { // viewWillAppear could be called after the full screen video has finished playing
        self.webView.frame = self.view.frame;
        self.webView.alpha = 0.0;
        [self.view addSubview:self.webView];
    }

    [self performSelector:@selector(fadeWebViewIn)
               withObject:nil
               afterDelay:kSPDelayForFadingWebViewIn];
}

- (void)viewDidAppear:(BOOL)animated
{
    // When the orientation change happens and the UIWebview is not currently shown (like when
    // playing a video with the native player), the UIWebView is not notified. So we'll force it
    [self refreshWebViewOrientation];
    if (!_viewDidAppearPreviously) {
        _viewDidAppearPreviously = YES;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.webView) {
        self.webView.alpha = 0.0;
    }
}

#pragma mark - Orientation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.lockToLandscape) {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    } else {
        return YES;
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations
{
    if (self.lockToLandscape) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#endif

- (CGRect)fullScreenFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    
    CGRect fullScreenFrame;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        fullScreenFrame = applicationFrame;
    } else {
        fullScreenFrame = CGRectMake(applicationFrame.origin.y,
                                     applicationFrame.origin.x,
                                     applicationFrame.size.height,
                                     applicationFrame.size.width);
    }
    
    return fullScreenFrame;
}

#pragma mark - Status bar preference

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark -

- (void)fadeWebViewIn {
    [UIView animateWithDuration:kSPDurationForFadeWebViewInAnimation animations:^{
        self.webView.alpha = 1.0;
    }];
}

#pragma mark - SPVideoPlaybackDelegate methods
- (void)playVideoFromNetwork:(NSString *)network video:(NSString *)video showAlert:(BOOL)showAlert alertMessage:(NSString *)alertMessage clickThroughURL:(NSURL *)clickThroughURL
{
    self.tpnName = network;
    self.video = video;

    NSString *decodedVideoURL = [video SPURLDecodedString];
    NSURL *videoURL = [NSURL URLWithString:decodedVideoURL];

    // Sometimes we might receive an offer without a scheme, just //s3.amazonaws.com/..., for example.
    // In these cases we append the http scheme
    if (![videoURL scheme]) {
        decodedVideoURL = [NSString stringWithFormat:@"http:%@", decodedVideoURL];
        videoURL = [NSURL URLWithString:decodedVideoURL];
    }

    self.semaphore = dispatch_semaphore_create(0);
    SPVideoPlayerViewController *playerViewController = [[SPVideoPlayerViewController alloc] initWithVideo:videoURL
                                                                                                 showAlert:showAlert
                                                                                              alertMessage:alertMessage
                                                                                           clickThroughUrl:clickThroughURL];
    playerViewController.delegate = self;
    self.videoViewController = playerViewController;

    __weak SPBrandEngageViewController *weakSelf = self;
    [self presentViewController:playerViewController animated:YES completion:^{
        dispatch_semaphore_signal(weakSelf.semaphore);
    }];
}

- (void)timeUpdate:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    [self.webView notifyOfVideoEvent:@"timeupdate" forTPN:self.tpnName
                         contextData:@{SPTPNIDParameter: self.video,
                                       @"currentTime": [NSNumber numberWithDouble:currentTime],
                                       @"duration": [NSNumber numberWithDouble:duration]}];
}

#pragma mark - SPVideoPlaybackStateDelegate
- (void)videoPlaybackStarted
{
    [self.webView notifyOfVideoEvent:@"playing" forTPN:self.tpnName contextData:@{SPTPNIDParameter: self.video}];
}

- (void)videoPlaybackEnded:(BOOL)videoWasAborted
{
    // In case of an error (invalid URL, for example), the controller will be dismissed while
    // still being presented. To fix this, we are creating a semaphore while the player is being presented
    __weak SPBrandEngageViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [weakSelf.videoViewController dismissViewControllerAnimated:!videoWasAborted completion:^{
                if (videoWasAborted) {
                    [weakSelf.webView notifyOfVideoEvent:@"cancel" forTPN:weakSelf.tpnName contextData:@{SPTPNIDParameter: weakSelf.video}];
                } else {
                    [weakSelf.webView notifyOfVideoEvent:@"ended" forTPN:weakSelf.tpnName contextData:@{SPTPNIDParameter: weakSelf.video}];
                }
                weakSelf.videoViewController = nil;
            }];
        });
#if OS_OBJECT_HAVE_OBJC_SUPPORT
#else
        dispatch_release(weakSelf.semaphore);
#endif
    });
}

- (void)refreshWebViewOrientation
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"$(window).trigger('orientationchange')"];
}
- (void)browserWillOpen
{
    [self.webView notifyOfVideoEvent:@"clickThrough" forTPN:self.tpnName
                         contextData:@{SPTPNIDParameter: self.video}];

}

@end
