//
//  SPBrandEngageClient.m
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPBrandEngageClient.h"
#import "SPLogger.h"
#import "iToast.h"
#import "SPReachability.h"
#import "SPVirtualCurrencyServerConnector_SDKPrivate.h"
#import "SponsorPaySDK.h"
#import "SPTargetedNotificationFilter.h"

#define kSPMBEJSCoreURL @"http://be.sponsorpay.com/mobile"

static NSString *MBEJSCoreURL = kSPMBEJSCoreURL;

typedef enum {
    MUST_QUERY_SERVER_FOR_OFFERS,
    QUERYING_SERVER_FOR_OFFERS,
    READY_TO_SHOW_OFFERS,
    SHOWING_OFFERS
} SPBrandEngageClientOffersRequestStatus;

static BOOL runningOniOS5OrNewer();
static BOOL runningOniOS6OrNewer();

@interface SPBrandEngageClient ()

@property (retain, nonatomic) SPBrandEngageWebView *BEWebView;
@property (retain) SPBrandEngageViewController *activeBEViewController;
@property (retain) UIViewController *viewControllerToRestore;

@property (readwrite, retain, nonatomic) NSString *appId;
@property (readwrite, retain, nonatomic) NSString *userId;
@property (readwrite, retain, nonatomic) NSString *currencyName;

- (NSURLRequest *)requestForWebViewMBEJsCore;
- (void)dismissActiveBEViewController;

- (void)didChangePublisherParameters;
- (void)didEnterBackground;
- (void)userReturnedAfterFollowingOffer;
- (void)requestOffersTimerDue;

- (void)showRewardNotification;

- (void)setUpInternetReachabilityNotifier;
- (void)reachabilityChanged:(NSNotification*)note;
- (void)didLoseInternetConnection;

- (void)invokeDelegateWithStatus:(SPBrandEngageClientStatus)status;
- (void)showErrorAlertWithMessage:(NSString *)message;

+ (UIViewController *)swapRootViewControllerTo:(UIViewController *)toVC
                          withAnimationOptions:(UIViewAnimationOptions)animationOptions
                                    completion:(void (^)(void))completion;
@end

@implementation SPBrandEngageClient
{
    SPBrandEngageClientOffersRequestStatus _offersRequestStatus;
    NSMutableDictionary *_customParams;
    BOOL _mustRestoreStatusBarOnPlayerDismissal;
    SPReachability *_internetReachability;
}

#pragma mark - Properties

@synthesize appId = _sappId, userId = _suserId, currencyName = _currencyName;

- (BOOL)setCustomParamWithKey:(NSString *)key value:(NSString *)value
{
    if (_customParams && [[_customParams objectForKey:key] isEqualToString:value]) {
        return YES;
    }
    
    if (![self canChangePublisherParameters]) {
        [SPLogger log:@"Cannot add custom parameter while a request to the server is going on"
         " or an offer is being presented to the user."];
    } else {
        if (!_customParams) {
            _customParams = [[NSMutableDictionary alloc] init];
        }
        [_customParams setObject:value forKey:key];
        [self didChangePublisherParameters];
        return YES;
    }
    
    return NO;
}

- (BOOL)canChangePublisherParameters
{
    return (_offersRequestStatus == MUST_QUERY_SERVER_FOR_OFFERS)
        || (_offersRequestStatus == READY_TO_SHOW_OFFERS);
}

- (void)didChangePublisherParameters
{
    _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
}

@synthesize delegate = _delegate;

@synthesize BEWebView = _BEWebView;

- (SPBrandEngageWebView *)BEWebView
{
    if (!_BEWebView) {
        _BEWebView = [[SPBrandEngageWebView alloc] init];
        _BEWebView.brandEngageDelegate = self;
    }
    return _BEWebView;
}

@synthesize activeBEViewController = _activeBEViewController;

#pragma mark - Initializing and deallocing

- (id)init
{
    self = [super init];
    
    if (self) {
        _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
        self.shouldShowRewardNotificationOnEngagementCompleted = YES;
        
        [self setUpInternetReachabilityNotifier];
        [self registerForCurrencyNameChangeNotification];
    }
    
    return self;
}

- (id)initWithAppId:(NSString *)appId
             userId:(NSString *)userId
       currencyName:(NSString *)currencyName
           delegate:(id<SPBrandEngageClientDelegate>)delegate
{
    self = [self init]; // because this constructor has been deprecated, - init is our new designated initializer
    
    if (self) {
        self.appId = appId;
        self.userId = userId;
        self.currencyName = currencyName;
        self.delegate = delegate;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.appId = nil;
    self.userId = nil;
    [_customParams release];
    [_internetReachability release];
    
    [super dealloc];
}

#pragma mark - Public methods

- (BOOL)canRequestOffers
{
    return _offersRequestStatus == MUST_QUERY_SERVER_FOR_OFFERS
            || _offersRequestStatus == READY_TO_SHOW_OFFERS;
}

- (BOOL)requestOffers
{
    if (![self canRequestOffers]) {
        [SPLogger log:@"SPBrandEngageClient cannot request offers at this point. "
         "It might be requesting offers right now or an offer might be currently being presented to the user."];

        return NO;
    }

    if (runningOniOS5OrNewer()) {
        _offersRequestStatus = QUERYING_SERVER_FOR_OFFERS;
        
        [self.BEWebView loadRequest:[self requestForWebViewMBEJsCore]];
        
        [self performSelector:@selector(requestOffersTimerDue) withObject:nil
                   afterDelay:kSPMBERequestOffersTimeout];
    } else {
        // iOS 5 or newer is required.
        [self performSelector:@selector(callDelegateWithNoOffers) withObject:nil
                   afterDelay:0.0];
    }
    
    
    return YES;
}

- (BOOL)canStartOffers
{
    return _offersRequestStatus == READY_TO_SHOW_OFFERS;
}

- (BOOL)startWithParentViewController:(UIViewController *)parentViewController
{
    if (![self canStartOffers]) {
        [SPLogger log:@"SPBrandEngageClient is not ready to show offers. Call -requestOffers: "
         "and wait until your delegate is called with the confirmation that offers have been received."];

        [self invokeDelegateWithStatus:ERROR];
        
        return NO;
    }
    
    _offersRequestStatus = SHOWING_OFFERS;
    
    [self.BEWebView startOffer];
    
    if (![UIApplication sharedApplication].statusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        _mustRestoreStatusBarOnPlayerDismissal = YES;
    }
    
    SPBrandEngageViewController *brandEngageVC = [[SPBrandEngageViewController alloc] initWithWebView:self.BEWebView];
    
    self.activeBEViewController = brandEngageVC;
    [brandEngageVC release];
    
    if (runningOniOS6OrNewer()) {
        [parentViewController presentViewController:self.activeBEViewController
                                           animated:YES
                                         completion:nil];
    } else {
        self.viewControllerToRestore = [[self class] swapRootViewControllerTo:brandEngageVC
                                                         withAnimationOptions:UIViewAnimationOptionTransitionCurlDown
                                                                   completion:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    return YES;
}

# pragma mark - Interrupting engagement if the host app enters background

- (void)didEnterBackground
{
    _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
    [self dismissActiveBEViewController];
    
    [self invokeDelegateWithStatus:CLOSE_ABORTED];
}

#pragma mark - SPBrandEngageWebViewControllerDelegate methods

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
  javascriptReportedOffers:(int)numberOfOffers
{
    BOOL areOffersAvailable = (numberOfOffers > 0);
    
    _offersRequestStatus = areOffersAvailable ? READY_TO_SHOW_OFFERS : MUST_QUERY_SERVER_FOR_OFFERS;
    
    if ([self.delegate respondsToSelector:@selector(brandEngageClient:didReceiveOffers:)]) {
        [self.delegate brandEngageClient:self didReceiveOffers:areOffersAvailable];
    }
}

- (void)brandEngageWebViewJavascriptOnStarted:(SPBrandEngageWebView *)BEWebView
{
    [SPLogger log:@"OnStarted event received"];
    
    [self invokeDelegateWithStatus:STARTED];
}

- (void)brandEngageWebViewOnAborted:(SPBrandEngageWebView *)BEWebView
{
    _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
    
    [self dismissActiveBEViewController];
    
    [self invokeDelegateWithStatus:CLOSE_ABORTED];
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView didFailWithError:(NSError *)error
{
    SPBrandEngageClientOffersRequestStatus preErrorStatus = _offersRequestStatus;
    _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
    
    // Show dialog only if we are showing offers
    if (preErrorStatus == SHOWING_OFFERS) {
        NSString *errorMessage = nil;
        
        if ([error.domain isEqualToString:kSPMBEWebViewJavascriptErrorDomain]) {
            errorMessage = kSPMBEErrorDialogMessageDefault;
        } else {
            errorMessage = kSPMBEErrorDialogMessageOffline;
        }
        
        [self showErrorAlertWithMessage:errorMessage];
    }
    else if (preErrorStatus == QUERYING_SERVER_FOR_OFFERS) {
        [self invokeDelegateWithStatus:ERROR];
    }
    
}

- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView requestsToCloseFollowingOfferURL:(NSURL *)offerURL
{
    BOOL willOpenURL = NO;
    if (offerURL) {
        willOpenURL = [[UIApplication sharedApplication] openURL:offerURL];
    }
    
    if (willOpenURL) {
        [BEWebView stopLoading];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userReturnedAfterFollowingOffer)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [SPLogger log:@"Application will follow offer url: %@", offerURL];
    } else {
        [self showRewardNotification];
    }

    _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
    
    [self dismissActiveBEViewController];
    
    [self invokeDelegateWithStatus:CLOSE_FINISHED];    
}

#pragma mark - Handling user's return after completing engagement

- (void)userReturnedAfterFollowingOffer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [SPLogger log:@"User returned to app after following offer. Will show notification."];

    [self showRewardNotification];
}

#pragma mark - Internet connection status change management

- (void)setUpInternetReachabilityNotifier
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification object:nil];
    
    if (!_internetReachability)
        _internetReachability = [[SPReachability reachabilityForInternetConnection] retain];
    
    [_internetReachability startNotifier];
}

//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification*)note
{
	SPReachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [SPReachability class]]);
    
    SPNetworkStatus currentNetworkStatus = [curReach currentReachabilityStatus];
    
    switch (currentNetworkStatus) {
        case ReachableViaWiFi:
            [SPLogger log:@"Internet is now reachable via WiFi"];
            break;
        case ReachableViaWWAN:
            [SPLogger log:@"Internet is now reachable via WWAN (cellular connection)"];
            break;
        case NotReachable:
            [SPLogger log:@"Connection to the internet has been lost"];
            [self didLoseInternetConnection];
            break;
        default:
            [SPLogger log:@"Unexpected network status received: %d", currentNetworkStatus];
            break;
    }
}

- (void)didLoseInternetConnection
{
    if (_offersRequestStatus == SHOWING_OFFERS) {
        _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;
        [self showErrorAlertWithMessage:kSPMBEErrorDialogMessageOffline];
    }
}

#pragma mark - Error alerts

- (void)showErrorAlertWithMessage:(NSString *)message
{
    UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:kSPMBEErrorDialogTitle
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:kSPMBEErrorDialogButtonTitleDismiss
                                                   otherButtonTitles:nil];
    [errorAlertView show];
    [errorAlertView release];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self dismissActiveBEViewController];
    [self invokeDelegateWithStatus:ERROR];
}

#pragma mark - Utility methods

- (NSURLRequest *)requestForWebViewMBEJsCore
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithBaseURLString:MBEJSCoreURL];

    [urlGenerator setAppID:self.appId];
    [urlGenerator setUserID:self.userId];
    [urlGenerator setParameterWithKey:kSPURLParamKeyCurrencyName
                          stringValue:self.currencyName];
    [urlGenerator setParameterWithKey:@"sdk" stringValue:@"on"];
    
    if (_customParams) {
        [urlGenerator setParametersFromDictionary:_customParams];
    }
    
    NSURL *requestURL = [urlGenerator generatedURL];
    
    [SPLogger log:@"URL Request for core JS in BE WebView: %@", requestURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    return request;
}

- (void)dismissActiveBEViewController
{
    if (!_activeBEViewController) {
        [SPLogger log:@"no active BEViewController to dismiss"];
        return;
    }
    
    void (^vcDismissedCompletionHandler)(void) = ^void(void) {
        [self.BEWebView removeFromSuperview];
        self.BEWebView = nil; // Won't reuse BEWebView between engagements
    };
    
    if (runningOniOS6OrNewer()) {
        [_activeBEViewController.presentingViewController
         dismissViewControllerAnimated:YES
         completion:vcDismissedCompletionHandler];
    } else {
        NSAssert(self.viewControllerToRestore, @"%@.viewControllerToRestore is nil!", [self class]);
        
        [[self class] swapRootViewControllerTo:self.viewControllerToRestore
                          withAnimationOptions:UIViewAnimationOptionTransitionCurlUp
                                    completion:vcDismissedCompletionHandler];
        self.viewControllerToRestore = nil;
    }
    
    [_activeBEViewController release];
    _activeBEViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    if (_mustRestoreStatusBarOnPlayerDismissal) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [SPLogger log:@"Restored status bar"];
    }
}

- (void)requestOffersTimerDue
{
    if (_offersRequestStatus == QUERYING_SERVER_FOR_OFFERS) {
        [self.BEWebView stopLoading];
        [self.BEWebView park];
        _offersRequestStatus = MUST_QUERY_SERVER_FOR_OFFERS;

        [self callDelegateWithNoOffers];
    }
}

- (void)callDelegateWithNoOffers
{
    if ([self.delegate respondsToSelector:@selector(brandEngageClient:didReceiveOffers:)]) {
        [self.delegate brandEngageClient:self didReceiveOffers:NO];
    }
}

- (void)showRewardNotification
{
    [SPLogger log:@"showRewardNotification"];

    if (!self.shouldShowRewardNotificationOnEngagementCompleted) {
        return;
    }
    
    [[[[iToast makeText:kSPMBERewardNotificationText]
       setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
}

- (void)invokeDelegateWithStatus:(SPBrandEngageClientStatus)status
{
    if ([self.delegate respondsToSelector:@selector(brandEngageClient:didChangeStatus:)])
        [self.delegate brandEngageClient:self didChangeStatus:status];
    else
        [SPLogger log:@"SP Brand Engage Client Delegate: %@ cannot be notified of status change "
         "because it doesn't respond to selector brandEngageClient:didChangeStatus:", self.delegate];
}

+ (UIViewController *)swapRootViewControllerTo:(UIViewController *)toVC
                          withAnimationOptions:(UIViewAnimationOptions)animationOptions
                                    completion:(void (^)(void))completion
{
#define kSPRootVCSwapAnimationDuration 1.0
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *fromVC = keyWindow.rootViewController;
    void (^animationCompletionHandler)(BOOL) = nil;
    
    if (completion) {
        animationCompletionHandler = ^(BOOL finished){
            if (finished)
                completion();
        };
    }
    
    [UIView transitionFromView:fromVC.view
                        toView:toVC.view
                      duration:kSPRootVCSwapAnimationDuration
                       options:animationOptions
                    completion:animationCompletionHandler];
    
    [keyWindow setRootViewController:toVC];
    
    return fromVC;
}

#pragma mark - Currency name change notification

- (void)registerForCurrencyNameChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currencyNameChanged:)
                                                 name:SPCurrencyNameChangeNotification
                                               object:nil];
}

- (void)currencyNameChanged:(NSNotification *)notification
{
    if ([SPTargetedNotificationFilter instanceWithAppId:self.appId
                                                 userId:self.userId
                            shouldRespondToNotification:notification]) {
        id newCurrencyName = notification.userInfo[SPNewCurrencyNameKey];
        if ([newCurrencyName isKindOfClass:[NSString class]]) {
            self.currencyName = newCurrencyName;
            [SPLogger log:@"%@ currency name is now: %@", self, self.currencyName];
        }
    }
}

#pragma mark - NSObject selectors

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {appId=%@ userId=%@}",
            [super description], self.appId, self.userId];
}

#pragma mark - Core URL override

+ (void)overrideMBEJSCoreURLWithURLString:(NSString *)overridingURL
{
    [MBEJSCoreURL release];
    MBEJSCoreURL = [overridingURL retain];
}

+ (void)restoreDefaultMBEJSCoreURL
{
    [self overrideMBEJSCoreURLWithURLString:kSPMBEJSCoreURL];
}

@end

#pragma mark - Utilities

static BOOL checkForiOSVersion(NSString *reqSysVer) {
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    return ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
}

static BOOL runningOniOS5OrNewer() {
    static BOOL didCacheResult = NO, cachedResult;
    
    if (!didCacheResult) {
        cachedResult = checkForiOSVersion(@"5.0");
        didCacheResult = YES;
    }
    
    return cachedResult;
}

static BOOL runningOniOS6OrNewer() {
    static BOOL didCacheResult = NO, cachedResult;
    
    if (!didCacheResult) {
        cachedResult = checkForiOSVersion(@"6.0");
        didCacheResult = YES;
    }
    
    return cachedResult;
}
