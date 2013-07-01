//
//  SPMBEWebView.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageWebView.h"
#import "SPLogger.h"
#import "NSURL+SPParametersParsing.h"
#import "NSString+SPURLEncoding.h"

#define kSPCustomURLScheme                          @"sponsorpay"

#define kSPRequestOffersAnswer                      @"requestOffers"
#define kSPNumberOfOffersParameterKey               @"n"

#define kSPRequestStartStatus                       @"start"
#define kSPRequestStatusParameterKey                @"status"
#define kSPRequestStatusParameterStartedValue       @"STARTED"
#define kSPRequestStatusParameterCloseFinishedValue @"CLOSE_FINISHED"
#define kSPRequestStatusParameterCloseAbortedValue  @"CLOSE_ABORTED"
#define kSPRequestStatusParameterError              @"ERROR"

#define kSPRequestExit                              @"exit"
#define kSPRequestURLParameterKey                   @"url"


#define kSPJsInvokationStartOffer @"Sponsorpay.MBE.SDKInterface.do_start()"

@interface SPBrandEngageWebView ()

@property (retain) UIButton *closeButton;

- (void)processSponsorPayScheme:(NSURL *)url;
- (void)javascriptReportedOffers:(int)numberOfOffers;
- (void)javascriptStartStatusNotificationReceivedWithStatus:(NSString *)status
                               followOfferURLParameterValue:(NSString *)urlString;
- (void)javascriptExitNotificationReceivedWithOfferURLParameterValue:(NSString *)urlParametervalue;

- (void)startOfferTimerDue;
- (void)showCloseButton;
- (void)hideCloseButton;
- (void)closeButtonWasTapped;
@end

@implementation SPBrandEngageWebView
{
    BOOL _startNotificationReceived;
}

#pragma mark - Properties

@synthesize brandEngageDelegate;

@synthesize closeButton = _closeButton;

#pragma mark - Housekeeping

- (id)init
{
    self = [super init];
    if (self) {
        self.mediaPlaybackRequiresUserAction = NO;
        self.allowsInlineMediaPlayback = YES;
        self.scrollView.scrollEnabled = NO;
        self.delegate = self;
    }
    return self;
}

- (void)dealloc
{
//    [SPLogger log:@"brandengage webview: %@ is being deallocated", self];
    self.delegate = nil;
    self.closeButton = nil;
    [super dealloc];
}

#pragma mark - UIWebView delegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
	NSString *scheme = [url scheme];
    if ([scheme isEqualToString:kSPCustomURLScheme]) {
        [self processSponsorPayScheme:url];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    switch (error.code) {
        case 102: // Loadingus interruptus
            [SPLogger log:@"Loading of BrandEngageWebView was interrupted. This is normal if we are, for instance, leaving the app to follow an offer."];
            break;
        case -1004: // "Could not connect to the server."
        case -1009: // "The Internet connection appears to be offline." error
            [SPLogger log:@"BrandEndageWebView couldn't load because due to a network issue: %d, %@", error.code, error.localizedDescription];
            if (self.delegate) {
                [self.brandEngageDelegate brandEngageWebView:self didFailWithError:error];
            }
            break;
        default:
            [SPLogger log:@"Brand Engage webView:didFailLoadWithError: %d %@", error.code, error.localizedDescription];
            break;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    [SPLogger log:@"Brand Engage webViewDidFinishLoad:"];
}

#pragma mark -

- (void)javascriptReportedOffers:(int)numberOfOffers
{
    if (brandEngageDelegate) {
        [brandEngageDelegate brandEngageWebView:self javascriptReportedOffers:numberOfOffers];
    }
}

- (void)javascriptStartStatusNotificationReceivedWithStatus:(NSString *)status
                               followOfferURLParameterValue:(NSString *)encodedURLString
{
    if ([status isEqualToString:kSPRequestStatusParameterStartedValue]) {
        _startNotificationReceived = YES;
        [self hideCloseButton];
        if (brandEngageDelegate) {
            [brandEngageDelegate brandEngageWebViewJavascriptOnStarted:self];
        }
    } else if ([status isEqualToString:kSPRequestStatusParameterCloseFinishedValue]) {
        [self exitCheckingForOfferURL:encodedURLString];
    } else if ([status isEqualToString:kSPRequestStatusParameterCloseAbortedValue]) {
        if (brandEngageDelegate) {
            [brandEngageDelegate brandEngageWebViewOnAborted:self];
        }
    } else if ([status isEqualToString:kSPRequestStatusParameterError]) {
        if (brandEngageDelegate) {
            NSError *errorToReport = [NSError errorWithDomain:kSPMBEWebViewJavascriptErrorDomain
                                                         code:0 userInfo:nil];
            [brandEngageDelegate brandEngageWebView:self didFailWithError:errorToReport];
        }
    }
}

- (void)javascriptExitNotificationReceivedWithOfferURLParameterValue:(NSString *)encodedURLString
{
    [self exitCheckingForOfferURL:encodedURLString];
}

- (void)exitCheckingForOfferURL:(NSString *)encodedURLString
{
    if (brandEngageDelegate) {
        NSURL *offerURL = nil;
        if (encodedURLString && ![encodedURLString isEqualToString:@""]) {
            if (encodedURLString) {
                NSString *unencodedURLString = [encodedURLString SPURLDecodedString];
                offerURL = [NSURL URLWithString:unencodedURLString];
            }
        }
        [brandEngageDelegate brandEngageWebView:self requestsToCloseFollowingOfferURL:offerURL];
    }
}

- (void)startOfferTimerDue
{
    if (!_startNotificationReceived) {
        [self showCloseButton];
    }
}

- (void)showCloseButton
{
#define kSPMBENativeCloseButtonSideSize     32
#define kSPMBENativeCloseButtonInsetSize     4
#define kSPMBENativeCloseButtonMarginRight   4
#define kSPMBENativeCloseButtonMarginTop     4
    
#define kSPMBENativeCloseButtonFadeAnimationDuration 1.0

    if (!self.closeButton) {
        CGFloat xPosition = self.bounds.size.width - kSPMBENativeCloseButtonMarginRight - kSPMBENativeCloseButtonSideSize;
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition,
                                                                           kSPMBENativeCloseButtonMarginTop,
                                                                           kSPMBENativeCloseButtonSideSize,
                                                                           kSPMBENativeCloseButtonSideSize)];
        closeButton.contentEdgeInsets = UIEdgeInsetsMake(kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize,
                                                         kSPMBENativeCloseButtonInsetSize);
        closeButton.backgroundColor = [UIColor clearColor];
        [closeButton setImage:[UIImage imageNamed:@"CloseX"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeButtonWasTapped)
              forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = closeButton;
        [closeButton release];
    }
    
    self.closeButton.alpha = 0.0;
    [UIView animateWithDuration:kSPMBENativeCloseButtonFadeAnimationDuration
                     animations:^{
                         self.closeButton.alpha = 1.0;
                     }];
    [self addSubview:self.closeButton];
}

- (void)hideCloseButton
{
    if (self.closeButton && self.closeButton.superview) {
        [UIView animateWithDuration:kSPMBENativeCloseButtonFadeAnimationDuration
                         animations:^{
                             self.closeButton.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.closeButton removeFromSuperview];
                         }];
    }
}


- (void)closeButtonWasTapped
{
    if (brandEngageDelegate) {
        [brandEngageDelegate brandEngageWebViewOnAborted:self];
    }
}

- (void)startOffer
{
    _startNotificationReceived = NO;
    [self stringByEvaluatingJavaScriptFromString:kSPJsInvokationStartOffer];
    [self performSelector:@selector(startOfferTimerDue) withObject:nil
               afterDelay:kSPMBEStartOfferTimeout];
}

- (void)park
{
    [self loadData:[@"" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
          MIMEType:@"text/plain"
  textEncodingName:@"utf-8"
           baseURL:nil];
}


#pragma mark - SponsorPay schema handling

- (void)processSponsorPayScheme:(NSURL *)url
{
   [SPLogger log:@"Processing SponsorPay scheme: %@", [url absoluteString]];
    
    NSString *command = [url host];
    NSDictionary *parameters = [url SPQueryDictionary];

    if ([command isEqualToString:kSPRequestOffersAnswer]) {
        NSString *numberOfOffersAsString = [parameters objectForKey:kSPNumberOfOffersParameterKey];
        int numberOfOffers = [numberOfOffersAsString intValue];
        [self javascriptReportedOffers:numberOfOffers];
    } else if ([command isEqualToString:kSPRequestStartStatus]) {
        NSString *statusString = [parameters objectForKey:kSPRequestStatusParameterKey];
        NSString *urlString = [parameters objectForKey:kSPRequestURLParameterKey];
        [self javascriptStartStatusNotificationReceivedWithStatus:statusString followOfferURLParameterValue:urlString];
    } else if ([command isEqualToString:kSPRequestExit]) {
        NSString *urlString = [parameters objectForKey:kSPRequestURLParameterKey];
        [self javascriptExitNotificationReceivedWithOfferURLParameterValue:urlString];
    }
}

@end
