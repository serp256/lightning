//
//  SPInterstitialViewController.m
//  SponsorPay iOS SDK
//
//  Copyright 2011 SponsorPay. All rights reserved.
//

#import "SPInterstitialViewController.h"
#import "SPAdvertisementViewController_SDKPrivate.h"
#import "SPAdvertisementViewControllerSubclass.h"

#import "SPURLGenerator.h"
#import "SP_SDK_versions.h"
#import "SPPersistence.h"
#import "SPLogger.h"

#define DEFAULT_SKIN_VALUE @"DEFAULT"

#pragma mark url params exclusive to the interstitial
static NSString *const SPURLParamKeyInterstitial = @"interstitial";
static NSString *const SPURLParamValueInterstitial = @"on";
#pragma mark -

#pragma mark animation parameters
static const NSTimeInterval SPInterstitialWebViewIntroAnimationLength = 1.0;
static const NSTimeInterval SPInterstitialWebViewOutroAnimationLength = 0.5;
#pragma mark -

static const NSTimeInterval SPDefaultInterstitialLoadingTimeout = 5.0;
static const BOOL SPDefaultInterstitialShouldFinishOnRedirect = YES;


// The base url to retrieve the interstitial from
#define INTERSTITIAL_BASE_URL @"https://iframe.sponsorpay.com/mobile"


static int offsetCounter = 0;
static NSString *interstitialBaseUrl = INTERSTITIAL_BASE_URL;

@interface SPInterstitialViewController ()

@property (retain, nonatomic) NSHTTPURLResponse *initialResponse;
@property (retain, nonatomic) NSURLConnection *initialRequestConnection;
@property (retain, nonatomic) NSMutableData *downloadedInterstitialData;
@property (assign) SPInterstitialRequestStatus requestStatus;

@end

@implementation SPInterstitialViewController {
    BOOL _usingLegacyMode;
}

#pragma mark - Deprecated initializers

- (id)initWithUserId:(NSString *)theUserId
               appId:(NSString *)theAppId
{
    return [self initWithUserId:theUserId
                          appId:theAppId
                  backgroundUrl:nil
                           skin:DEFAULT_SKIN_VALUE
                  loadingTimeout:SPDefaultInterstitialLoadingTimeout];
}

- (id)initWithUserId:(NSString *)theUserId
               appId:(NSString *)theAppId 
       backgroundUrl:(NSString *)theBackgroundUrl
                skin:(NSString *)theSkinName
{
	return [self initWithUserId:theUserId
                          appId:theAppId
                  backgroundUrl:theBackgroundUrl
                           skin:theSkinName 
                  loadingTimeout:SPDefaultInterstitialLoadingTimeout];
}

- (id)initWithUserId:(NSString *)theUserId
               appId:(NSString *)theAppId
       backgroundUrl:(NSString *)theBackgroundUrl
                skin:(NSString *)theSkinName
      loadingTimeout:(NSTimeInterval)loadingTimeOut
{
    self = [super initWithUserId:theUserId appId:theAppId disposalBlock:nil];
    
	if (self) {
        _usingLegacyMode = YES;
        
        self.shouldFinishOnRedirect = SPDefaultInterstitialShouldFinishOnRedirect;
        self.skin = theSkinName;
        self.backgroundImageUrl = theBackgroundUrl;
        self.requestStatus = NOT_WAITING;
        self.loadingTimeout = loadingTimeOut;
        
        [self startInterstitialFlow];
    }
    
    return self;
}

#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
        _usingLegacyMode = NO;
        self.loadingTimeout = SPDefaultInterstitialLoadingTimeout;
        self.skin = DEFAULT_SKIN_VALUE;
        self.shouldFinishOnRedirect = SPDefaultInterstitialShouldFinishOnRedirect;
    }
    
    return self;
}

#pragma mark - Standard Interstitial flow

- (void)startLoadingWithParentViewController:(UIViewController *)parentVC
{
    self.publisherViewController = parentVC;
    [self startInterstitialFlow];
}

-(void)startInterstitialFlow
{
    [self animateLoadingViewIn];
    [self sendInitialInterstitialRequest];
    [self startInitialRequestTimeOutTimer];
}

- (void)sendInitialInterstitialRequest
{
    NSURL *url = [self URLforInterstitial];
    [SPLogger log:@"SponsorPay Mobile Interstitial will be requested using url: %@", url];
    
	if (self.initialResponse) {
        [self.initialRequestConnection cancel];
        self.initialRequestConnection = nil;
    }
    
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	self.initialRequestConnection = [NSURLConnection connectionWithRequest:requestObj delegate:self];
    
    self.requestStatus = WAITING_FOR_INITIAL_REQUEST_RESPONSE;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    int statusCode = self.initialResponse.statusCode;
    
    if ([self isInterstitialAvailableAccordingToHttpStatusCode:statusCode]) {
        [self loadReceivedDataIntoWebView];
        offsetCounter ++;
    } else {
        [self animateLoadingViewOut];
        [self notifyDelegateOfStatus:NO_INTERSTITIAL_AVAILABLE];
        self.requestStatus = NOT_WAITING;
    }
    
    self.downloadedInterstitialData = nil;
    self.initialResponse = nil;
    self.initialRequestConnection = nil;
}

- (BOOL)isInterstitialAvailableAccordingToHttpStatusCode:(int)statusCode
{
    // "OK" and "Redirect" codes mean we've got an interstitial
    return statusCode >= 200 && statusCode < 400;
}

- (void)loadReceivedDataIntoWebView
{
    [self.webView loadData:self.downloadedInterstitialData
                  MIMEType:self.initialResponse.MIMEType
          textEncodingName:self.initialResponse.textEncodingName
                   baseURL:self.initialResponse.URL];
    self.requestStatus = WAITING_FOR_WEBVIEW_TO_LOAD_INITIAL_CONTENTS;
}

- (void)webViewDidFinishLoad
{
    if (self.requestStatus == WAITING_FOR_WEBVIEW_TO_LOAD_INITIAL_CONTENTS) {
        [self animateLoadingViewOut];
        [self attachWebViewToViewHierarchy];
        
        if (_usingLegacyMode) {
            [self animateInterstitialWebViewIn];
        } else {
            [self presentAsChildOfViewController:self.publisherViewController];
        }
        
        [self notifyDelegateOfStatus:AD_SHOWN];
        self.requestStatus = NOT_WAITING;
    }
}

-(void)cancelInterstitialRequestDueToTimeout
{
    if (self.requestStatus != NOT_WAITING) {
        [self cancelInterstitialRequest];
        [self notifyDelegateOfStatus:ERROR_TIMEOUT];
    }
}

- (BOOL)cancelInterstitialRequest
{
    BOOL didCancelRequestOrLoading;
    switch (self.requestStatus) {
        case WAITING_FOR_INITIAL_REQUEST_RESPONSE:
            [self.initialRequestConnection cancel];
            self.initialRequestConnection = nil;
            [self animateLoadingViewOut];
            didCancelRequestOrLoading = YES;
            break;
        case WAITING_FOR_WEBVIEW_TO_LOAD_INITIAL_CONTENTS:
            [self.webView stopLoading];
            [self animateLoadingViewOut];
            didCancelRequestOrLoading = YES;
            break;
        default:
        case NOT_WAITING:
            didCancelRequestOrLoading = NO;
            break;
    }
    return didCancelRequestOrLoading;
}

- (void)startInitialRequestTimeOutTimer
{
    [self performSelector:@selector(cancelInterstitialRequestDueToTimeout)
               withObject:nil
               afterDelay:self.loadingTimeout];
}

- (NSURL *)URLforInterstitial
{
    SPURLGenerator *urlGenerator =
    [SPURLGenerator URLGeneratorWithBaseURLString:interstitialBaseUrl];
        
    [urlGenerator setAppID:self.appId];
    [urlGenerator setUserID:self.userId];
    
    [urlGenerator setParameterWithKey:kSPURLParamKeyCurrencyName
                          stringValue:self.currencyName];
    
    [urlGenerator setParameterWithKey:kSPURLParamKeySkin
                          stringValue:self.skin];
    
    [urlGenerator setParameterWithKey:SPURLParamKeyInterstitial
                        stringValue:SPURLParamValueInterstitial];
    [urlGenerator setParameterWithKey:kSPURLParamKeyAllowCampaign
                        stringValue:kSPURLParamValueAllowCampaignOn];
    [urlGenerator setParameterWithKey:kSPURLParamKeyOffset
                         integerValue:offsetCounter];
    
    [urlGenerator setParametersFromDictionary:self.customParameters];
    
    if (self.backgroundImageUrl && [self.backgroundImageUrl length]) {
        [urlGenerator setParameterWithKey:kSPURLParamKeyBackground
                            stringValue:self.backgroundImageUrl];
    }
    
    return [urlGenerator generatedURL];
}

#pragma mark - Error handling

- (void)handleWebViewLoadingError:(NSError *)error
{
    [SPLogger log:@"Interstitial's WebView did fail load with error: %@", error ];
    
    [self dismissAnimated:YES];
    [self animateLoadingViewOut];
    
    [self notifyDelegateOfStatus:ERROR_NETWORK];
}

#pragma mark - Delegate notification

-(void)notifyDelegateOfStatus:(SPInterstitialViewControllerStatus)status {
    if (self.delegate) {
        [self.delegate interstitialViewController:self didChangeStatus:status];
    }
}

#pragma mark - Animation and view hierarchy manipulation methods

- (void)animateLoadingViewIn
{
    [self.loadingProgressView presentWithAnimationTypes:(SPAnimationTypeFade | SPAnimationTypeTranslateBottomUp)];
}

- (void)animateInterstitialWebViewIn
{
    CGPoint animInitCenterPoint;
    CGPoint center = self.view.center;
    CGRect frame = self.view.frame;
    
    animInitCenterPoint.x = center.x;
    animInitCenterPoint.y = frame.size.height + (self.webView.frame.size.height / 2);
    
    self.webView.center = animInitCenterPoint;

    // Apply block-based animations
    [UIView animateWithDuration:SPInterstitialWebViewIntroAnimationLength
                     animations:^{
                         self.webView.center = self.view.center;
                     }
     ];
}

- (void)animateInterstitialWebViewOut
{
    CGPoint hideInterstitialCenterPoint;
    CGPoint center = self.view.center;
    CGRect frame = self.view.frame;
    
    hideInterstitialCenterPoint.x = center.x;
    hideInterstitialCenterPoint.y = frame.size.height + (self.webView.frame.size.height / 2);
    
    [UIView animateWithDuration:SPInterstitialWebViewOutroAnimationLength
                     animations:^{
                         self.webView.center = hideInterstitialCenterPoint;
                     }
                     completion:^(BOOL finished){
                         [self dismissAnimated:NO];
                     }
     ];
}

-(void)dismissAnimated:(BOOL)animated
{
    if (_usingLegacyMode) {
        if (animated) {
            [self animateInterstitialWebViewOut];
        } else {
            [self.webView removeFromSuperview];
            [self notifyDelegateOfStatus:CLOSED];
        }
    } else {
        [self notifyDelegateOfStatus:CLOSED];
        [super dismissFromPublisherViewControllerAnimated:animated];
    }
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)receivedResponse
{
    NSAssert([receivedResponse isMemberOfClass:[NSHTTPURLResponse class]],
             @"%@ expects an NSHTTPURLResponse passed to its connection:didReceiveResponse: method. It got instead an instance of %@",
             [self class], [receivedResponse class]);
    
    self.initialResponse = (NSHTTPURLResponse *)receivedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData
{
    [self.downloadedInterstitialData appendData:receivedData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self animateLoadingViewOut];
    [self notifyDelegateOfStatus:ERROR_NETWORK];
    self.initialRequestConnection = nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}

#pragma mark - Housekeeping

@synthesize downloadedInterstitialData = _downloadedInterstitialData;
- (NSMutableData *)downloadedInterstitialData
{
    if (!_downloadedInterstitialData) {
        _downloadedInterstitialData = [[NSMutableData alloc] initWithCapacity:8192];
    }
    return _downloadedInterstitialData;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget: self];

    self.skin = nil;
    self.backgroundImageUrl = nil;
    self.initialResponse = nil;
    
    self.initialRequestConnection = nil;
    
    self.downloadedInterstitialData = nil;
    
    [super dealloc];
}

#pragma mark - Development / Staging / Production URLs management

+ (void)overrideBaseURLWithURLString:(NSString *)newUrl {
    [interstitialBaseUrl release];
    interstitialBaseUrl = [newUrl retain];
}

+ (void)restoreBaseURLToDefault {
    [SPInterstitialViewController overrideBaseURLWithURLString:INTERSTITIAL_BASE_URL];
}
 
@end
