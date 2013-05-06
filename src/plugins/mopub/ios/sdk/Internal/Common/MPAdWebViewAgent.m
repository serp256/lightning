//
//  MPAdWebViewAgent.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPAdWebViewAgent.h"
#import "MPAdConfiguration.h"
#import "MPGlobal.h"
#import "MPLogging.h"
#import "CJSONDeserializer.h"
#import "MPAdDestinationDisplayAgent.h"
#import "NSURL+MPAdditions.h"
#import "UIWebView+MPAdditions.h"
#import "MPAdWebView.h"
#import "MPInstanceProvider.h"

NSString * const kMoPubURLScheme = @"mopub";
NSString * const kMoPubCloseHost = @"close";
NSString * const kMoPubFinishLoadHost = @"finishLoad";
NSString * const kMoPubFailLoadHost = @"failLoad";
NSString * const kMoPubCustomHost = @"custom";

@interface MPAdWebViewAgent ()

@property (nonatomic, retain) MPAdConfiguration *configuration;
@property (nonatomic, assign) id<MPAdWebViewAgentDelegate> delegate;
@property (nonatomic, retain) MPAdDestinationDisplayAgent *destinationDisplayAgent;
@property (nonatomic, assign) BOOL shouldHandleRequests;

@end

@implementation MPAdWebViewAgent

@synthesize configuration = _configuration;
@synthesize delegate = _delegate;
@synthesize destinationDisplayAgent = _destinationDisplayAgent;
@synthesize customMethodDelegate = _customMethodDelegate;
@synthesize shouldHandleRequests = _shouldHandleRequests;

- (id)initWithAdWebViewFrame:(CGRect)frame delegate:(id<MPAdWebViewAgentDelegate>)delegate customMethodDelegate:(id)customMethodDelegate;
{
    self = [super init];
    if (self) {
        self.view = [[MPInstanceProvider sharedProvider] buildMPAdWebViewWithFrame:frame delegate:self];
        self.destinationDisplayAgent = [[MPInstanceProvider sharedProvider] buildMPAdDestinationDisplayAgentWithDelegate:self];
        self.delegate = delegate;
        self.customMethodDelegate = customMethodDelegate;
        self.shouldHandleRequests = YES;
    }
    return self;
}

- (void)dealloc
{
    self.configuration = nil;
    self.destinationDisplayAgent = nil;
    self.view.delegate = nil;
    self.view = nil;
    [super dealloc];
}

#pragma mark - Public

- (void)loadConfiguration:(MPAdConfiguration *)configuration
{
    self.configuration = configuration;

    if ([configuration hasPreferredSize]) {
        CGRect frame = self.view.frame;
        frame.size.width = configuration.preferredSize.width;
        frame.size.height = configuration.preferredSize.height;
        self.view.frame = frame;
    }

    [self.view mp_setScrollable:configuration.scrollable];
    [self.view loadHTMLString:[configuration adResponseHTMLString]
                         baseURL:nil];
}

- (void)invokeJavaScriptForEvent:(MPAdWebViewEvent)event
{
    switch (event) {
        case MPAdWebViewEventAdDidAppear:
            [self.view stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"];
            break;
        case MPAdWebViewEventAdDidDisappear:
            [self.view stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"];
            break;
        default:
            break;
    }
}

- (void)stopHandlingRequests
{
    self.shouldHandleRequests = NO;
}

- (void)continueHandlingRequests
{
    self.shouldHandleRequests = YES;
}

#pragma mark - <MPAdDestinationDisplayAgentDelegate>

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)displayAgentWillPresentModal
{
    [self.delegate adActionWillBegin:self.view];
}

- (void)displayAgentWillLeaveApplication
{
    [self.delegate adActionWillLeaveApplication:self.view];
}

- (void)displayAgentDidDismissModal
{
    [self.delegate adActionDidFinish:self.view];
}

#pragma mark - <UIWebViewDelegate>

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (!self.shouldHandleRequests) {
        return NO;
    }

    NSURL *URL = [request URL];
    if ([[URL scheme] isEqualToString:kMoPubURLScheme]) {
        [self performActionForMoPubSpecificURL:URL];
        return NO;
    } else if ([self shouldIntercept:URL navigationType:navigationType]) {
        [self interceptURL:URL];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - MoPub-specific URL handlers
- (void)performActionForMoPubSpecificURL:(NSURL *)URL
{
    MPLogDebug(@"MPAdWebView - loading MoPub URL: %@", URL);
    NSString *host = [URL host];
    if ([host isEqualToString:kMoPubCloseHost]) {
        [self.delegate adDidClose:self.view];
    } else if ([host isEqualToString:kMoPubFinishLoadHost]) {
        [self.delegate adDidFinishLoadingAd:self.view];
    } else if ([host isEqualToString:kMoPubFailLoadHost]) {
        [self.delegate adDidFailToLoadAd:self.view];
    } else if ([host isEqualToString:kMoPubCustomHost]) {
        [self handleMoPubCustomURL:URL];
    } else {
        MPLogWarn(@"MPAdWebView - unsupported MoPub URL: %@", [URL absoluteString]);
    }
}

- (void)handleMoPubCustomURL:(NSURL *)URL
{
    NSDictionary *queryParameters = [URL mp_queryAsDictionary];
    NSString *selectorName = [queryParameters objectForKey:@"fnc"];
    NSString *oneArgumentSelectorName = [selectorName stringByAppendingString:@":"];
    SEL zeroArgumentSelector = NSSelectorFromString(selectorName);
    SEL oneArgumentSelector = NSSelectorFromString(oneArgumentSelectorName);

    if ([self.customMethodDelegate respondsToSelector:zeroArgumentSelector]) {
        [self.customMethodDelegate performSelector:zeroArgumentSelector];
    } else if ([self.customMethodDelegate respondsToSelector:oneArgumentSelector]) {
        CJSONDeserializer *deserializer = [CJSONDeserializer deserializerWithNullObject:NULL];
        NSData *data = [[queryParameters objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dataDictionary = [deserializer deserializeAsDictionary:data error:NULL];

        [self.customMethodDelegate performSelector:oneArgumentSelector
                                        withObject:dataDictionary];
    } else {
        MPLogError(@"Custom method delegate does not implement custom selectors %@ or %@.",
                   selectorName, oneArgumentSelectorName);
    }
}

#pragma mark - URL Interception
- (BOOL)shouldIntercept:(NSURL *)URL navigationType:(UIWebViewNavigationType)navigationType
{
    if (!(self.configuration.shouldInterceptLinks)) {
        return NO;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return YES;
    } else if (navigationType == UIWebViewNavigationTypeOther) {
        return [[URL absoluteString] hasPrefix:[self.configuration clickDetectionURLPrefix]];
    } else {
        return NO;
    }
}

- (void)interceptURL:(NSURL *)URL
{
    NSURL *redirectedURL = URL;
    if (self.configuration.clickTrackingURL) {
        NSString *path = [NSString stringWithFormat:@"%@&r=%@",
                          self.configuration.clickTrackingURL.absoluteString,
                          [[URL absoluteString] URLEncodedString]];
        redirectedURL = [NSURL URLWithString:path];
    }

    [self.destinationDisplayAgent displayDestinationForURL:redirectedURL];
}

#pragma mark - Utility
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation
{
    [self forceRedraw];
}

- (void)forceRedraw
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    int angle = -1;
    switch (orientation)
    {
        case UIDeviceOrientationPortrait: angle = 0; break;
        case UIDeviceOrientationLandscapeLeft: angle = 90; break;
        case UIDeviceOrientationLandscapeRight: angle = -90; break;
        case UIDeviceOrientationPortraitUpsideDown: angle = 180; break;
        default: break;
    }

    if (angle == -1) return;

    // UIWebView doesn't seem to fire the 'orientationchange' event upon rotation, so we do it here.
    NSString *orientationEventScript = [NSString stringWithFormat:
                                        @"window.__defineGetter__('orientation',function(){return %d;});"
                                        @"(function(){ var evt = document.createEvent('Events');"
                                        @"evt.initEvent('orientationchange',true,true);window.dispatchEvent(evt);})();",
                                        angle];
    [self.view stringByEvaluatingJavaScriptFromString:orientationEventScript];

    // XXX: If the UIWebView is rotated off-screen (which may happen with interstitials), its
    // content may render off-center upon display. We compensate by setting the viewport meta tag's
    // 'width' attribute to be the size of the webview.
    NSString *viewportUpdateScript = [NSString stringWithFormat:
                                      @"document.querySelector('meta[name=viewport]')"
                                      @".setAttribute('content', 'width=%f;', false);",
                                      self.view.frame.size.width];
    [self.view stringByEvaluatingJavaScriptFromString:viewportUpdateScript];
}

@end
