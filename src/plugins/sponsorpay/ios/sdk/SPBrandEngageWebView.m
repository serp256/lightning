//
//  SPMBEWebView.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageWebView.h"
#import "SPLogger.h"
#import "NSURL+SPParametersParsing.h"
#import "NSURL+SPDescription.h"
#import "NSString+SPURLEncoding.h"
#import "NSDictionary+SPSerialization.h"
#import "SPResourceLoader.h"
#import "SPConstants.h"

// TODO: Change all of these to static NSStrings
#define kSPCustomURLScheme                          @"sponsorpay"

#define kSPRequestOffersAnswer                      @"requestOffers"
#define kSPNumberOfOffersParameterKey               @"n"

#define kSPRequestStartStatus                       @"start"
#define kSPRequestStatusParameterKey                @"status"
#define kSPRequestStatusParameterStartedValue       @"STARTED"
#define kSPRequestStatusParameterCloseFinishedValue @"CLOSE_FINISHED"
#define kSPRequestStatusParameterCloseAbortedValue  @"CLOSE_ABORTED"
#define kSPRequestStatusParameterError              @"ERROR"

#define kSPThirtPartyNetworkParameter               @"tpn"
#define kSPRequestPlay                              @"play"

#define kSPRequestExit                              @"exit"
#define kSPRequestURLParameterKey                   @"url"

#define kSPRequestInstall                           @"install"
#define kSPRequestInstallAppId                      @"id"

#define kSPJsInvocationStartOffer @"Sponsorpay.MBE.SDKInterface.do_start()"
#define kSPJsInvocationNotify @"Sponsorpay.MBE.SDKInterface.notify"
#define kSPJsInvocationGetOffer @"Sponsorpay.MBE.SDKInterface.do_getOffer()"

static NSString *const SPTPNLocalName = @"local";
static NSString *const SPTPNShowAlertParameter = @"showAlert";
static NSString *const SPTPNAlertMessageParameter = @"alertMessage";
static NSString *const SPTPNClickThroughURL = @"clickThroughUrl";

@interface SPBrandEngageWebView ()

@property (strong) UIButton *closeButton;

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
    SPLogDebug(@"MBEWebView %x initialized", [self hash]);

    return self;
}

- (void)dealloc
{
    SPLogDebug(@"MBEWebView %x is being deallocated", [self hash]);
    self.delegate = nil;
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
    SPLogDebug(@"[BET] Webview will start loading request: %@ with navigation type: %d", [request.URL SPPrettyDescription], navigationType);
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    switch (error.code) {
        case 102: // Loadingus interruptus
            SPLogDebug(@"Loading of BEWebView (%x) was interrupted. This is normal if we are, for instance, leaving the app to follow an offer.", [self hash]);
            break;
        case -1004: // "Could not connect to the server."
        case -1009: // "The Internet connection appears to be offline." error
            SPLogError(@"BEWebView (%x) couldn't load due to a network issue: %d, %@", [self hash], error.code, error.localizedDescription);
            if (self.delegate) {
                [self.brandEngageDelegate brandEngageWebView:self didFailWithError:error];
            }
            break;
        default:
            SPLogError(@"Brand Engage webView:(%x) didFailLoadWithError: %d %@", [self hash], error.code, error.localizedDescription);
            break;
    }
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
        [closeButton setImage:[self closeButtonImage] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeButtonWasTapped)
              forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = closeButton;
    }
    
    self.closeButton.alpha = 0.0;
    [UIView animateWithDuration:kSPMBENativeCloseButtonFadeAnimationDuration
                     animations:^{
                         self.closeButton.alpha = 1.0;
                     }];
    [self addSubview:self.closeButton];
}

- (UIImage *)closeButtonImage
{
    return [SPResourceLoader imageWithName:@"SPCloseX"];
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

- (BOOL)currentOfferUsesTPN
{
    NSString *usesTPNJSON = [self stringByEvaluatingJavaScriptFromString:kSPJsInvocationGetOffer];
    NSError *error;
    id usesTPN = [NSJSONSerialization JSONObjectWithData:[usesTPNJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                 options:0
                                                   error:&error];

    NSNumber *r = usesTPN[@"uses_tpn"];

    SPLogInfo(@"Current offer will be played through a third party network: %@", [r boolValue] ? @"YES" : @"NO");

    return [r boolValue];
}

- (void)startOffer
{
    _startNotificationReceived = NO;

    SPLogDebug(@"[BET] invoking %@", kSPJsInvocationStartOffer);
    [self stringByEvaluatingJavaScriptFromString:kSPJsInvocationStartOffer];
    [self performSelector:@selector(startOfferTimerDue) withObject:nil
               afterDelay:kSPMBEStartOfferTimeout];
}

#pragma mark - SponsorPay schema handling

- (void)processSponsorPayScheme:(NSURL *)url
{
    SPLogDebug(@"Processing SponsorPay scheme: %@", [url absoluteString]);
    
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
    } else if ([command isEqualToString:SPRequestValidate]) {
        NSString *tpnName = parameters[kSPThirtPartyNetworkParameter];
        NSDictionary *contextData = @{SPTPNIDParameter : parameters[SPTPNIDParameter]};

        SPLogInfo(@"MBE client asks to validate a third party network: %@", tpnName);

        [self.brandEngageDelegate brandEngageWebView:self
                             requestsValidationOfTPN:tpnName
                                         contextData:contextData];
    } else if ([command isEqualToString:kSPRequestPlay]) {
        NSString *tpnName = parameters[kSPThirtPartyNetworkParameter];
        NSDictionary *contextData = @{SPTPNIDParameter : parameters[SPTPNIDParameter]};

        SPLogInfo(@"[BET] MBE client asks to play an offer from a third party network: %@", tpnName);

        // Check if we should play using our own native player
        if ([tpnName isEqualToString:SPTPNLocalName]) {
            // Alert configuration
            BOOL showAlert = [parameters[SPTPNShowAlertParameter] isEqualToString:@"true"];
            NSString *alertMessage = [parameters[SPTPNAlertMessageParameter] SPURLDecodedString];

            // ClickThrough configuration
            NSString *clickThroughURLString = [parameters[SPTPNClickThroughURL] SPURLDecodedString];
            NSURL *clickThroughURL = [NSURL URLWithString:clickThroughURLString];

            [self.brandEngageDelegate brandEngageWebView:self playVideoFromLocalNetwork:tpnName video:parameters[SPTPNIDParameter] showAlert:showAlert alertMessage:alertMessage clickThroughURL:clickThroughURL];
        } else {
            [self.brandEngageDelegate brandEngageWebView:self
                                  requestsPlayVideoOfTPN:tpnName
                                             contextData:contextData];
        }
    } else if ([command isEqualToString:kSPRequestInstall]) {
        NSString *appId = parameters[kSPRequestInstallAppId];
        SPLogDebug(@"Opening store with app id: %@", appId);
        [self.brandEngageDelegate brandEngageWebView:self requestsStoreWithAppId:appId];
    }
}

#pragma mark -

- (void)notifyOfValidationResult:(NSString *)validationResult
                          forTPN:(NSString *)tpnName
                     contextData:(NSDictionary *)contextData
{
    NSString *contextDataString;
    if (contextData.count) {
        contextDataString = [NSString stringWithFormat:@", %@", [contextData SPComponentsJoined]];
    }

    NSString *js = [NSString stringWithFormat:@"%@('validate', {tpn:'%@', result:'%@'%@})",
                    kSPJsInvocationNotify, tpnName,
                    validationResult, contextDataString];

    SPLogDebug(@"%s (%x) invoking javascript in the webview: %@", __PRETTY_FUNCTION__ , [self hash], js);

    [self stringByEvaluatingJavaScriptFromString:js];
}

- (void)notifyOfVideoEvent:(NSString *)videoEventName
                    forTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData
{
    NSString *contextDataString;
    if (contextData.count) {
        contextDataString = [NSString stringWithFormat:@", %@", [contextData SPComponentsJoined]];
    }

    NSString *js = [NSString stringWithFormat:@"%@('play', {tpn:'%@', result:'%@'%@})",
                    kSPJsInvocationNotify, tpnName,
                    videoEventName, contextDataString];
    
    SPLogDebug(@"%s (%x) invoking javascript in the webview: %@", __PRETTY_FUNCTION__ , [self hash], js);

    [self stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark -

- (void)loadRequest:(NSURLRequest *)request
{
    SPLogDebug(@"MBEWebView %x will load request with URL %@",
     [self hash], request.URL.absoluteString);

    [super loadRequest:request];
}

@end
