//
//  SPAdvertisementViewController.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 10/22/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPAdvertisementViewController.h"
#import "SPAdvertisementViewController_SDKPrivate.h"
#import "SPAdvertisementViewControllerSubclass.h"
#import "SPTargetedNotificationFilter.h"
#import "SPLogger.h"
#import <StoreKit/StoreKit.h>

@interface SPAdvertisementViewController () <SKStoreProductViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *userId;
@property (readwrite, strong, nonatomic) NSString *currencyName;
@property (copy) SPViewControllerDisposalBlock disposalBlock;

- (id)initWithUserId:(NSString *)userId appId:(NSString *)appId;

@end

@implementation SPAdvertisementViewController {
    UIWebView *_webView;
    SPSchemeParser *_sponsorpaySchemeParser;
    SPLoadingIndicator *_loadingProgressView;
    UIViewController *_publisherViewController; // Can use parentViewController from iOS 5 on
}

#pragma mark - Initializers

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        [self registerForCurrencyNameChangeNotification];
    }
    
    return self;
}

- (id)initWithUserId:(NSString *)userId
               appId:(NSString *)appId
{
	self = [self init];
    
    if (self) {
        self.userId = userId;
        self.appId = appId;
 	}
    
    return self;
}

#pragma mark - UIViewController lifecycle

- (void)loadView
{
    UIView *rootView =
    [[UIView alloc] initWithFrame:[self fullScreenFrameForInterfaceOrientation:[self currentStatusBarOrientation]]];
    rootView.backgroundColor = [UIColor clearColor];
    rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = rootView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appWillEnterForegroundNotification:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)attachWebViewToViewHierarchy
{
    if (!self.webView.superview) {
        [self.view addSubview:self.webView];
    }
}

#pragma mark -

#pragma mark - Orientation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000

- (NSUInteger)supportedInterfaceOrientations
{
    //    return [self currentStatusBarOrientation];
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#endif

- (UIInterfaceOrientation)currentStatusBarOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (CGRect)fullScreenFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGRect applicationFrame = [[UIScreen mainScreen] bounds];
    
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

#pragma mark -

- (void)loadURLInWebView:(NSURL *) url
{
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:requestObj];
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
	if (self.webView != nil && self.webView.superview != nil ) {
		[self.webView reload];
	}
}

#pragma mark - Loading indicators management

- (void)animateLoadingViewIn
{
    [self.loadingProgressView presentWithAnimationTypes:SPAnimationTypeFade];
}

- (void)animateLoadingViewOut
{
    [[self loadingProgressView] dismiss];
}

#pragma mark - UIWebViewDelegate methods


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    self.sponsorpaySchemeParser.URL = request.URL;
    self.sponsorpaySchemeParser.shouldRequestCloseWhenOpeningExternalURL = self.shouldFinishOnRedirect;
    BOOL shouldContinueLoading = self.sponsorpaySchemeParser.requestsContinueWebViewLoading;

    NSString *command = self.sponsorpaySchemeParser.command;

    if ([command isEqualToString:SPONSORPAY_START_PATH]) {
        // Start command
        [self animateLoadingViewOut];
    } else if ([command isEqualToString:SPONSORPAY_EXIT_PATH]) {
        // Exit Command
        BOOL openingExternalDestination = self.sponsorpaySchemeParser.requestsOpeningExternalDestination;

        if (openingExternalDestination) {
            [[UIApplication sharedApplication] openURL:self.sponsorpaySchemeParser.externalDestination];
        }

        if (self.sponsorpaySchemeParser.requestsClosing) {
            [self dismissAnimated:!openingExternalDestination withStatus:self.sponsorpaySchemeParser.closeStatus];
        }

    } else if ([command isEqualToString:SPONSORPAY_INSTALL_PATH]) {
        // Install Command
        if ([SKStoreProductViewController class]) {
            [self openStoreWithAppId:self.sponsorpaySchemeParser.appId];
        } else {
            [self openITunesWithAppId:self.sponsorpaySchemeParser.appId
                      requestsClosing:self.sponsorpaySchemeParser.requestsClosing
                          closeStatus:self.sponsorpaySchemeParser.closeStatus];
        }
    }
    return shouldContinueLoading;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Error -999 is triggered when the WebView starts a request before the previous one was completed.
    // We assume that kind of error can be safely ignored.
    if ([error code] != -999) {
        if (!self.sponsorpaySchemeParser.requestsOpeningExternalDestination) {
            [self handleWebViewLoadingError:error];
        }
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self webViewDidFinishLoad];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (self.sponsorpaySchemeParser.requestsClosing) {
            [self dismissAnimated:YES withStatus:self.sponsorpaySchemeParser.closeStatus];
        }
    }
}

#pragma mark - Private Methods
- (void)openStoreWithAppId:(NSString *)appId
{
    SPLogDebug(@"Opening StoreKit with App Id: %@", appId);
    SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc] init];
    productViewController.delegate = self;
    [productViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: appId}
                                     completionBlock:^(BOOL result, NSError *error) {
        if (!error) {
            [self presentViewController:productViewController animated:YES completion:nil];

        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"An Error Happened", nil)
                                                                message:[error localizedDescription]
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];

}

- (void)openITunesWithAppId:(NSString *)appId requestsClosing:(BOOL)requestsClosing closeStatus:(NSInteger)closeStatus
{
    NSURL *iTunesURL = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.com/apps/id%@", appId]];
    SPLogDebug(@"Opening iTunes with URL: %@", iTunesURL);
    [[UIApplication sharedApplication] openURL:iTunesURL];

    if (requestsClosing) {
        [self dismissAnimated:NO withStatus:closeStatus];
    }

}
#pragma mark - Unimplemented methods

- (void)dismissAnimated:(BOOL)animated withStatus:(NSInteger)status
{
    
}

- (void)webViewDidFinishLoad
{
    
}

- (void)handleWebViewLoadingError:(NSError *)error
{
    
}

# pragma mark - Presentation of publisher's VC

- (void)presentAsChildOfViewController:(UIViewController *)parentViewController
{
    self.publisherViewController = parentViewController;
    [parentViewController presentViewController:self animated:YES completion:nil];
}

- (void)dismissFromPublisherViewControllerAnimated:(BOOL)animated
{
    if (!self.publisherViewController) {
        return;
    }

    UIViewController* publisherVC = self.publisherViewController;

    self.publisherViewController = nil;

    dispatch_async(dispatch_get_main_queue(), self.disposalBlock);

    [publisherVC dismissViewControllerAnimated:animated completion:nil];

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
            SPLogInfo(@"%@ currency name is now: %@", self, self.currencyName);
        }
    }
}

#pragma mark - Manually implemented properties

- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.delegate = self;
    }
    return _webView;
}

- (void)setWebView:(UIWebView *)webView
{
    [_webView setDelegate:nil];
    _webView = webView;
}

- (SPLoadingIndicator *)loadingProgressView
{
    if (nil == _loadingProgressView)
        _loadingProgressView = [[SPLoadingIndicator alloc] init];
    
    return _loadingProgressView;
}

- (void)setLoadingProgressView:(SPLoadingIndicator *)loadingProgressView
{
    _loadingProgressView = loadingProgressView;
}

- (SPSchemeParser *)sponsorpaySchemeParser {
    if (!_sponsorpaySchemeParser) {
        _sponsorpaySchemeParser = [[SPSchemeParser alloc] init];
    }
    return _sponsorpaySchemeParser;
}

- (void)setSponsorpaySchemeParser:(SPSchemeParser *)sponsorpaySchemeParser
{
    _sponsorpaySchemeParser = sponsorpaySchemeParser;
}

- (UIViewController *)publisherViewController
{
    return _publisherViewController;
}

- (void)setPublisherViewController:(UIViewController *)publisherViewController
{
    // This is an unsafe_unretained property
    _publisherViewController = publisherViewController;
}

#pragma mark - Store Kit delegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    if (self.sponsorpaySchemeParser.requestsClosing) {
        [self dismissAnimated:YES withStatus:self.sponsorpaySchemeParser.closeStatus];
    } else {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Housekeeping

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    SPLogDebug(@"Deallocing advertisement VC: %@", self);

    self.webView = nil;
    self.loadingProgressView = nil;
    self.sponsorpaySchemeParser = nil;
}

@end
