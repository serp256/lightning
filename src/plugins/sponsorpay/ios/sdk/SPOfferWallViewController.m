//
//  SPOfferWallViewController.m
//  SponsorPay iOS SDK
//
//  Copyright 2011 SponsorPay. All rights reserved.
//

#import "SPOfferWallViewController.h"
#import "SPAdvertisementViewController_SDKPrivate.h"
#import "SPAdvertisementViewControllerSubclass.h"

#import "SP_SDK_versions.h"
#import "SPURLGenerator.h"
#import "SPPersistence.h"
#import "SPSchemeParser.h"
#import "SPLogger.h"

#define OFFERWALL_BASE_URL		@"https://iframe.sponsorpay.com/mobile"
#define SHOULD_OFFERWALL_FINISH_ON_REDIRECT_DEFAULT NO

static const NSUInteger kOfferWallLoadingErrorAlertTag = 10;

static NSString *offerWallBaseUrl = OFFERWALL_BASE_URL;

@implementation SPOfferWallViewController {
    BOOL _usingLegacyMode;
    UIImageView* _closeCross;
}

#pragma mark - Deprecated initializers

- (id)initWithUserId:(NSString *)userId
               appId:(NSString *)appId
    customParameters:(NSDictionary *)customParameters
{
    self = [super initWithUserId:userId appId:appId disposalBlock:nil];
    
    if (self) {
        _usingLegacyMode = YES;
        self.customParameters = customParameters;
        self.shouldFinishOnRedirect = SHOULD_OFFERWALL_FINISH_ON_REDIRECT_DEFAULT;
    }
    
    return self;
}

- (id)initWithUserId:(NSString *)userId
               appId:(NSString *)appId
{
    return [self initWithUserId:userId appId:appId customParameters:nil];
}

#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
        _usingLegacyMode = NO;
    }

    return self;
}

#pragma mark - UIViewController lifecycle

- (void)loadView
{
    [super loadView];
    [self attachWebViewToViewHierarchy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_usingLegacyMode) {
        [self startLoadingOfferWall];
    }
}

#pragma mark - Standard OfferWall flow

- (void)showOfferWallWithParentViewController:(UIViewController *)parentViewController
{
    [self presentAsChildOfViewController:parentViewController];
    [self startLoadingOfferWall];
}

- (void)alignCloseCross {
    CGRect parentBnds = self.view.bounds;
    CGRect crossBnds = _closeCross.bounds;    
    _closeCross.frame = CGRectMake(CGRectGetWidth(parentBnds) - CGRectGetWidth(crossBnds) - 20, 20, CGRectGetWidth(crossBnds), CGRectGetHeight(crossBnds));
}

- (void)closeCrossTapped {    
    [self animateLoadingViewOut];
    [_closeCross removeFromSuperview];
    // [_closeCross release];

    [self dismissAnimated:YES];
}

- (void)startLoadingOfferWall
{
    NSURL *offerWallURL = [self URLForOfferWall];
    
    [SPLogger log:@"SponsorPay Mobile Offer Wall will be requested using url: %@", offerWallURL];

    NSBundle* bndl = [NSBundle mainBundle];
    NSString* imgPath = [bndl pathForResource:@"x" ofType:@"png"];
    UIImage* img = [UIImage imageWithContentsOfFile:imgPath];
    _closeCross = [[UIImageView alloc] initWithImage:img];
    [img release];

    [self alignCloseCross];   
    [self.view addSubview:_closeCross];

    UITapGestureRecognizer *tapRcgnzr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeCrossTapped)];
    [_closeCross addGestureRecognizer:tapRcgnzr];
    [_closeCross setUserInteractionEnabled:YES];

    [self animateLoadingViewIn];
    [self loadURLInWebView:offerWallURL];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self alignCloseCross];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (NSURL *)URLForOfferWall
{
    SPURLGenerator *urlGenerator = [SPURLGenerator URLGeneratorWithBaseURLString:offerWallBaseUrl];
    [urlGenerator setAppID:self.appId];
    [urlGenerator setUserID:self.userId];
    [urlGenerator setParameterWithKey:kSPURLParamKeyCurrencyName
                          stringValue:self.currencyName];

    [urlGenerator setParametersFromDictionary:self.customParameters];
        
    return [urlGenerator generatedURL];
}

- (void)webViewDidFinishLoad
{
    [self animateLoadingViewOut];
    [_closeCross removeFromSuperview];
    // [_closeCross release];
}

- (void)dismissAnimated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(offerWallViewController:isFinishedWithStatus:)]) {
        [self.delegate offerWallViewController:self isFinishedWithStatus:0];
    }

    if (!_usingLegacyMode) {
        [self dismissFromPublisherViewControllerAnimated:animated];
    }
}

#pragma mark - Error handling

- (void)handleWebViewLoadingError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [error localizedDescription]
                                                    message: nil
                                                   delegate: self
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles: nil];
    alert.tag = kOfferWallLoadingErrorAlertTag;
    [alert show];
    [alert autorelease];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kOfferWallLoadingErrorAlertTag) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(offerWallViewController:isFinishedWithStatus:)]) {
            [self.delegate offerWallViewController:self isFinishedWithStatus:SPONSORPAY_ERR_NETWORK];
        }
    }
}

#pragma mark - Development / Staging / Production URLs management

+ (void)overrideBaseURLWithURLString:(NSString *)newUrl
{
    [offerWallBaseUrl release];
    offerWallBaseUrl = [newUrl retain];
}

+ (void)restoreBaseURLToDefault
{
    [self overrideBaseURLWithURLString:OFFERWALL_BASE_URL];
}

@end
