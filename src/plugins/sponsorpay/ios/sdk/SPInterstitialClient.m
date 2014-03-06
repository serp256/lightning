//
//  SPInterstitialClient.m
//  SponsorPay iOS SDK
//
//  Copyright 2011-2013 SponsorPay. All rights reserved.
//

#import <objc/runtime.h>
#import "SPInterstitialClient.h"
#import "SPTPNManager.h"
#import "SPInterstitialClient_SDKPrivate.h"
#import "SPInterstitialResponse.h"
#import "SPInterstitialOffer.h"
#import "SPURLGenerator.h"
#import "SPRandomID.h"
#import "SPLogger.h"
#import "SPInterstitialEventHub.h"
#import "SPInterstitialEvent.h"
#import "SPConstants.h"

NSString *const SPInterstitialClientErrorDomain = @"SPInterstitialClientErrorDomain";
const NSInteger SPInterstitialClientCannotInstantiateAdapterErrorCode = -8;
const NSInteger SPInterstitialClientInvalidStateErrorCode = -9;
const NSInteger SPInterstitialClientConnectionErrorCode = -10;

NSString *const SPInterstitialClientErrorLoggableDescriptionKey = @"SPInterstitialClientErrorLoggableDescriptionKey";

static NSString *const kInterstitialProductionURLString = @"http://engine.sponsorpay.com/interstitial";

typedef NS_ENUM(NSInteger, SPInterstitialClientState) {
    SPInterstitialClientReadyToCheckOffersState,
    SPInterstitialClientRequestingOffersState,
    SPInterstitialClientValidatingOffersState,
    SPInterstitialClientReadyToShowInterstitialState,
    SPInterstitialClientShowingInterstitialState
};

BOOL SPInterstitialClientState_canCheckOffers(SPInterstitialClientState state) {
    return state == SPInterstitialClientReadyToCheckOffersState
        || state == SPInterstitialClientReadyToShowInterstitialState;
}

@interface SPInterstitialClient()

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, assign) BOOL didSetCredentials;

@property (strong, readonly, nonatomic) NSMutableDictionary *adapters;
@property (strong, nonatomic) NSString *interstitialEndPointURLString;
@property (strong, readonly, nonatomic) SPURLGenerator *URLGenerator;
@property (strong, nonatomic) NSString *lastRequestID;
@property (assign, nonatomic) SPInterstitialClientState state;
@property (strong, nonatomic) SPInterstitialEventHub *eventHub;

@property (strong, nonatomic) SPInterstitialOffer *selectedOffer;

@end

@implementation SPInterstitialClient {
    NSMutableDictionary *_adapters;
    SPURLGenerator *_URLGenerator;
}

/** Singleton because the SDKs wrapped in the underlying adapters might not support
 being instantiated multiple times **/
+ (instancetype)sharedClient
{
    static SPInterstitialClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc] init];
    });

    return _sharedClient;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.interstitialEndPointURLString = kInterstitialProductionURLString;
        self.state = SPInterstitialClientReadyToCheckOffersState;
        self.eventHub = [[SPInterstitialEventHub alloc] init];
        [self addObserver:self forKeyPath:@"appId" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"userId" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (BOOL)setAppId:(NSString *)appId userId:(NSString *)userId
{
    if (self.didSetCredentials) {
        return NO;
    }
    self.appId = appId;
    self.userId = userId;
    self.didSetCredentials = YES;
    _URLGenerator = nil;
    return YES;
}

- (void)setInterstitialEndPointURLString:(NSString *)interstitialEndPointURLString
{
    _interstitialEndPointURLString = interstitialEndPointURLString;
    _URLGenerator = nil;
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:@"appId"];
    [self removeObserver:self forKeyPath:@"userId"];
}

- (SPURLGenerator *)URLGenerator
{
    if (!_URLGenerator) {
        _URLGenerator = [SPURLGenerator URLGeneratorWithBaseURLString:self.interstitialEndPointURLString];
    }

    return _URLGenerator;
}

- (void)setinterstitialEndPointURLString:(NSString *)interstitialEndPointURLString
{
    _URLGenerator = nil; // Need to recreate generator with new end point URL
    _interstitialEndPointURLString = interstitialEndPointURLString;
}

# pragma mark - Adapter configuration
- (id<SPInterstitialNetworkAdapter>)adapterForNetworkName:(NSString *)networkName
{
    return [SPTPNManager getInterstitialAdapterForNetwork:networkName];
}

#pragma mark - Checking for available interstitial
- (void)checkInterstitialAvailable
{
    if (!SPInterstitialClientState_canCheckOffers(self.state)) {
        NSString *errorDescriptionFormat = @"%s cannot check for available interstitials at this point.";

        [self failWithInvalidStateErrorWithDescription:[NSString stringWithFormat:errorDescriptionFormat, __PRETTY_FUNCTION__]];
        return;
    }

    self.selectedOffer = nil;
    self.state = SPInterstitialClientRequestingOffersState;

    void(^requestCompletionHandler)(NSURLResponse *, NSData *, NSError *) =
    ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        SPInterstitialResponse *interstitialResponse =
        [SPInterstitialResponse responseWithURLResponse:response
                                                   data:data
                                        connectionError:connectionError];

        if (!interstitialResponse.isSuccessResponse) {
            self.state = SPInterstitialClientReadyToCheckOffersState;
            [self failWithErrorDescription:@"An error occurred while requesting interstitial offers"
                           underlyingError:interstitialResponse.error];
            return;
        }

        self.state = SPInterstitialClientValidatingOffersState;
        SPInterstitialOffer *selectedOffer = [self offerSelectedFromResponse:interstitialResponse];

        BOOL canShowInterstitial;
        SPInterstitialClientState newState;

        if (selectedOffer) {
            canShowInterstitial = YES;
            newState = SPInterstitialClientReadyToShowInterstitialState;
        } else {
            canShowInterstitial = NO;
            newState = SPInterstitialClientReadyToCheckOffersState;
        }

        self.selectedOffer = selectedOffer;
        self.state = newState;
        [self.delegate interstitialClient:self canShowInterstitial:canShowInterstitial];
    };

    NSURLRequest *requestForOffers = [self URLRequestForOffers];
    SPLogDebug(@"Requesting interstitial offers: %@", requestForOffers);
    [NSURLConnection sendAsynchronousRequest:requestForOffers
                                       queue:[self queueForRequestCallback]
                           completionHandler:requestCompletionHandler];
}

- (NSURLRequest *)URLRequestForOffers
{
    [self.URLGenerator setAppID:self.appId];
    [self.URLGenerator setUserID:self.userId];

    NSString *requestID = [SPRandomID randomIDString];
    [self.URLGenerator setParameterWithKey:SPUrlGeneratorRequestIDKey stringValue:requestID];
    self.lastRequestID = requestID;

    return [NSURLRequest requestWithURL:[self.URLGenerator generatedURL]];
}

- (NSOperationQueue *)queueForRequestCallback
{
    return [NSOperationQueue mainQueue];
}

- (SPInterstitialOffer *)offerSelectedFromResponse:(SPInterstitialResponse *)response
{
    for (SPInterstitialOffer *offer in response.orderedOffers) {
        if ([self canShowInterstitialFromNetwork:offer]) {
            [self fireNotification:SPInterstitialEventTypeFill offer:offer];
            return offer;
        }

        // Checks if the adapter is integrated. A no_fill should not be sent in this case.
        if ([self adapterForNetworkName:offer.networkName]) {
            [self fireNotification:SPInterstitialEventTypeNoFill offer:offer];
        }
    }
    return nil;
}

- (BOOL)canShowInterstitialFromNetwork:(SPInterstitialOffer *)offer
{
    id<SPInterstitialNetworkAdapter> adapter = [self adapterForNetworkName:offer.networkName];
    [adapter setDelegate:self];
    if (adapter) {
        [self fireNotification:SPInterstitialEventTypeRequest offer:offer];
    } else {
        SPLogError(@"Interstitial Adapter for %@ could not be found", offer.networkName);
    }

    return [adapter canShowInterstitial];
}

#pragma mark - Showing an interstitial

- (void)showInterstitialFromViewController:(UIViewController *)parentViewController
{
    if (self.state != SPInterstitialClientReadyToShowInterstitialState) {
        NSString *errorDescription = [NSString stringWithFormat:@"%s is not ready to show any interstitial offer.", __PRETTY_FUNCTION__];
        [self failWithInvalidStateErrorWithDescription:errorDescription];
        return;
    }
    self.state = SPInterstitialClientShowingInterstitialState;

    id<SPInterstitialNetworkAdapter> adapter = [self adapterForNetworkName:self.selectedOffer.networkName];

    [adapter showInterstitialFromViewController:parentViewController];
}

#pragma mark - SPInterstitialNetworkAdapterDelegate

- (void)adapterDidShowInterstitial:(id<SPInterstitialNetworkAdapter>)adapter
{
    [self fireNotification:SPInterstitialEventTypeImpression offer:self.selectedOffer];
    self.state = SPInterstitialClientReadyToCheckOffersState;
    [self.delegate interstitialClientDidShowInterstitial:self];
}

- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter
    didDismissInterstitialWithReason:(SPInterstitialDismissReason)dismissReason
{
    switch (dismissReason) {
        case SPInterstitialDismissReasonUserClickedOnAd:
            [self fireNotification:SPInterstitialEventTypeClick offer:self.selectedOffer];
            break;
        case SPInterstitialDismissReasonUserClosedAd:
            [self fireNotification:SPInterstitialEventTypeClose offer:self.selectedOffer];
             break;
        default:
             break;
    }

    [self.delegate interstitialClient:self didDismissInterstitialWithReason:dismissReason];
}

- (void)adapter:(id<SPInterstitialNetworkAdapter>)adapter didFailWithError:(NSError *)error
{
    SPLogError(@"Error received from %@: %@",adapter.networkName, [error localizedDescription]);
    [self fireNotification:SPInterstitialEventTypeError offer:self.selectedOffer];
    [self failWithError:error];
}

#pragma mark - Errors

- (void)failWithCannotInstantiateAdapterErrorWithDescription:(NSString *)description
{
    NSError *error =
    [NSError errorWithDomain:SPInterstitialClientErrorDomain
                        code:SPInterstitialClientCannotInstantiateAdapterErrorCode
                    userInfo:@{SPInterstitialClientErrorLoggableDescriptionKey : description}];

    [self failWithError:error];
}

- (void)failWithInvalidStateErrorWithDescription:(NSString *)description
{
    NSError *error =
    [NSError errorWithDomain:SPInterstitialClientErrorDomain
                        code:SPInterstitialClientInvalidStateErrorCode
                    userInfo:@{SPInterstitialClientErrorLoggableDescriptionKey : description}];

    [self failWithError:error];
}

- (void)failWithErrorDescription:(NSString *)errorDescription underlyingError:(NSError *)underlyingError
{

    NSError *error =
    [NSError errorWithDomain:SPInterstitialClientErrorDomain
                        code:SPInterstitialClientConnectionErrorCode
                    userInfo:@{SPInterstitialClientErrorLoggableDescriptionKey : errorDescription,
                               NSUnderlyingErrorKey : underlyingError}];

    [self failWithError:error];
}

- (void)failWithError:(NSError *)error
{
    [self.delegate interstitialClient:self didFailWithError:error];
}

- (void)clearCredentials
{
    self.appId = nil;
    self.userId = nil;
    self.didSetCredentials =  NO;
}

+ (void)overrideBaseURLWithURLString:(NSString *)newURLString eventHub:(NSString *)newEventHubURL
{
    [[self sharedClient] setInterstitialEndPointURLString:newURLString];
    [[self sharedClient] overrideEventHubURL:newEventHubURL];
}

+ (void)restoreBaseURLToDefault
{
    [[self sharedClient] setInterstitialEndPointURLString:kInterstitialProductionURLString];
    [[self sharedClient] restoreEventHubURLToDefault];
}

- (void)overrideEventHubURL:(NSString *)newEventHubURL
{
    [self.eventHub overrideBaseURLWithURLString:newEventHubURL];
}
- (void)restoreEventHubURLToDefault
{
    [self.eventHub restoreBaseURLToDefault];
}

# pragma mark - KVO Observers
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    // Key-Value Observer for change in the appId - Updates the appId from eventHub
    if ([keyPath isEqualToString:@"appId"]) {
        self.eventHub.appId = [change objectForKey:NSKeyValueChangeNewKey];
    } else if ([keyPath isEqualToString:@"userId"]) {
        self.eventHub.userId = [change objectForKey:NSKeyValueChangeNewKey];
    }
}

# pragma mark - Helper methods
- (void)fireNotification:(SPInterstitialEventType)eventType offer:(SPInterstitialOffer *)offer
{
    SPInterstitialEvent *event = [[SPInterstitialEvent alloc] initWithEventType:eventType network:offer.networkName adId:offer.adId requestId:self.lastRequestID];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPInterstitialEventNotification object:event];
}
@end

NSString *SPStringFromInterstitialDismissReason(SPInterstitialDismissReason reason)
{
    switch (reason) {
        case SPInterstitialDismissReasonUnknown:
            return @"SPInterstitialDismissReasonUnknown";
        case SPInterstitialDismissReasonUserClickedOnAd:
            return @"SPInterstitialDismissReasonUserClickedOnAd";
        case SPInterstitialDismissReasonUserClosedAd:
            return @"SPInterstitialDismissReasonUserClosedAd";
    }
}
