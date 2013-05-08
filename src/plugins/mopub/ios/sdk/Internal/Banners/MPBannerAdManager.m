//
//  MPBannerAdManager.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "MPBannerAdManager.h"

#import "MPAdapterMap.h"
#import "MPAdServerURLBuilder.h"
#import "MPBannerDelegateHelper.h"
#import "MPKeywordProvider.h"
#import "MPTimer.h"

#import "MPAdConfiguration.h"

NSString * const kTimerNotificationName = @"Autorefresh";
const CGFloat kMoPubRequestRetryInterval = 60.0;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPBannerAdManager ()

@property (nonatomic, retain) MPBannerDelegateHelper *delegateHelper;
@property (nonatomic, readwrite, copy) NSURL *failoverURL;
@property (nonatomic, retain) UIView *nextAdContentView;

- (void)initializeTimerTarget;
- (void)registerForApplicationStateTransitionNotifications;
- (void)scheduleAutorefreshTimerIfEnabled;
- (void)scheduleAutorefreshTimer;
- (void)cancelPendingAutorefreshTimer;
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;

- (NSString *)adUnitID;
- (NSString *)keywords;
- (NSArray *)locationDescriptionPair;
- (BOOL)isTesting;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPBannerAdManager

@synthesize loading = _loading;
@synthesize adView = _adView;
@synthesize delegateHelper = _delegateHelper;
@synthesize failoverURL = _failoverURL;
@synthesize nextAdContentView = _nextAdContentView;
@synthesize autorefreshTimer = _autorefreshTimer;
@synthesize ignoresAutorefresh = _ignoresAutorefresh;

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeTimerTarget];
        [self registerForApplicationStateTransitionNotifications];

        _communicator = [[MPAdServerCommunicator alloc] init];
        _communicator.delegate = self;

        _adapterManager = [[MPBannerAdapterManager alloc] initWithDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    _adView = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_autorefreshTimer invalidate];
    [_autorefreshTimer release];
    [_timerTarget release];

    [_communicator cancel];
    [_communicator setDelegate:nil];
    [_communicator release];

    [_adapterManager setDelegate:nil];
    [_adapterManager release];

    [_delegateHelper release];

    [_failoverURL release];

    [super dealloc];
}

#pragma mark - Public

- (void)loadAdWithURL:(NSURL *)URL
{
    if (_loading) {
        MPLogWarn(@"Banner view is already loading an ad. Wait for previous load to finish.");
        return;
    }

    _loading = YES;

    URL = (URL) ? URL : [MPAdServerURLBuilder URLWithAdUnitID:[self adUnitID]
                                                     keywords:[self keywords]
                                                locationArray:[self locationDescriptionPair]
                                                      testing:[self isTesting]];

    MPLogInfo(@"Banner view (%p) loading ad with MoPub server URL: %@", self.adView, URL);

    [_communicator loadURL:URL];
}

- (void)refreshAd
{
    [self cancelPendingAutorefreshTimer];
    [self loadAdWithURL:nil];
}

- (void)forceRefreshAd
{
    [self cancelAd];
    [self refreshAd];
}

- (void)cancelAd
{
    _loading = NO;
    [_communicator cancel];
}

#pragma mark - Request data

- (NSString *)adUnitID
{
    return [self.adView adUnitId];
}

- (NSString *)keywords
{
    return [self.adView keywords];
}

- (NSArray *)locationDescriptionPair
{
    return [self.adView locationDescriptionPair];
}

- (BOOL)isTesting
{
    return [self.adView isTesting];
}

#pragma mark - MPAdServerCommunicatorDelegate

- (void)communicatorDidReceiveAdConfiguration:(MPAdConfiguration *)configuration
{
    if (configuration.adType == MPAdTypeUnknown) {
        [self communicatorDidFailWithError:nil];
        return;
    }

    configuration.adSize = _adView.originalSize;

    if (configuration.refreshInterval != -1) {
        self.autorefreshTimer = [MPTimer timerWithTimeInterval:configuration.refreshInterval
                                                        target:_timerTarget
                                                      selector:@selector(postNotification)
                                                      userInfo:nil
                                                       repeats:NO];
    } else {
        self.autorefreshTimer = nil;
    }

    self.failoverURL = configuration.failoverURL;

    [_adapterManager loadAdapterForConfig:configuration];
}

- (void)communicatorDidFailWithError:(NSError *)error
{
    _loading = NO;

    if (!self.autorefreshTimer || ![self.autorefreshTimer isValid]) {
        [self scheduleDefaultAutorefreshTimer];
    } else {
        [self scheduleAutorefreshTimerIfEnabled];
    }

    if ([[self adViewDelegate] respondsToSelector:@selector(adViewDidFailToLoadAd:)]) {
        [[self adViewDelegate] adViewDidFailToLoadAd:[self adView]];
    }

    MPLogError(@"Ad view (%p) failed to get a valid response from MoPub server. Error: %@",
               self.adView, error);
}

#pragma mark - Initialization helpers

- (void)initializeTimerTarget
{
    _timerTarget = [[MPTimerTarget alloc] initWithNotificationName:kTimerNotificationName];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forceRefreshAd)
                                                 name:kTimerNotificationName
                                               object:_timerTarget];
}

- (void)registerForApplicationStateTransitionNotifications
{
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];

    // iOS version > 4.0: Register for relevant application state transition notifications.
    if (&UIApplicationDidEnterBackgroundNotification != nil)
    {
        [defaultNotificationCenter addObserver:self
                                      selector:@selector(applicationDidEnterBackground)
                                          name:UIApplicationDidEnterBackgroundNotification
                                        object:[UIApplication sharedApplication]];
    }
    if (&UIApplicationWillEnterForegroundNotification != nil)
    {
        [defaultNotificationCenter addObserver:self
                                      selector:@selector(applicationWillEnterForeground)
                                          name:UIApplicationWillEnterForegroundNotification
                                        object:[UIApplication sharedApplication]];
    }
}

#pragma mark - UIApplication notification listeners

- (void)applicationDidEnterBackground
{
    [self.autorefreshTimer pause];
}

- (void)applicationWillEnterForeground
{
    _autorefreshTimerNeedsScheduling = NO;
    if (!_ignoresAutorefresh) {
        [self forceRefreshAd];
    }
}

#pragma mark - Setters

- (void)setAdView:(MPAdView *)adView {
    _adView = adView;

    self.delegateHelper = [[[MPBannerDelegateHelper alloc] initWithAdView:adView] autorelease];
    self.ignoresAutorefresh = adView.ignoresAutorefresh;
}

- (void)setIgnoresAutorefresh:(BOOL)ignoresAutorefresh
{
    _ignoresAutorefresh = ignoresAutorefresh;
    if (_ignoresAutorefresh) {
        MPLogDebug(@"Ad view (%p) is now ignoring autorefresh.", self.adView);
        if ([self.autorefreshTimer isScheduled]) [self.autorefreshTimer pause];
    } else {
        MPLogDebug(@"Ad view (%p) is no longer ignoring autorefresh.", self.adView);
        if ([self.autorefreshTimer isScheduled]) [self.autorefreshTimer resume];
    }
}

#pragma mark - Rotation

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation
{
    [_adapterManager rotateToOrientation:orientation];
}

#pragma mark - Autorefresh timer

- (BOOL)hasInvalidOrNilAutorefreshTimer
{
    return ![self.autorefreshTimer isValid];
}

- (void)scheduleDefaultAutorefreshTimer
{
    [self.autorefreshTimer invalidate];
    self.autorefreshTimer = [MPTimer timerWithTimeInterval:kMoPubRequestRetryInterval
                                                    target:_timerTarget
                                                  selector:@selector(postNotification)
                                                  userInfo:nil
                                                   repeats:NO];
    [self scheduleAutorefreshTimerIfEnabled];
}

- (void)scheduleAutorefreshTimerIfEnabled
{
    if (_ignoresAutorefresh) return;
    else [self scheduleAutorefreshTimer];
}

- (void)scheduleAutorefreshTimer
{
    if (_adActionInProgress) {
        _autorefreshTimerNeedsScheduling = YES;
        MPLogDebug(@"Ad action in progress: MPTimer will be scheduled after action ends.");
    } else if ([self.autorefreshTimer isScheduled]) {
        MPLogDebug(@"Tried to schedule the autorefresh timer, but it was already scheduled.");
    } else if (self.autorefreshTimer == nil) {
        MPLogDebug(@"Tried to schedule the autorefresh timer, but it was nil.");
    } else {
        [self.autorefreshTimer scheduleNow];
    }
}

- (void)cancelPendingAutorefreshTimer
{
    [self.autorefreshTimer invalidate];
}

- (void)pauseAutorefresh
{
    _previousIgnoresAutorefresh = _ignoresAutorefresh;
    [self setIgnoresAutorefresh:YES];
}

- (void)resumeAutorefreshIfEnabled
{
    [self setIgnoresAutorefresh:_previousIgnoresAutorefresh];
}

- (NSTimeInterval)refreshInterval
{
    return [self.autorefreshTimer initialTimeInterval];
}

#pragma mark - MPBannerAdapterManagerDelegate

- (id<MPAdViewDelegate>)adViewDelegate
{
    return [self.delegateHelper adViewDelegate];
}

- (UIViewController *)rootViewController
{
    return [self.delegateHelper rootViewController];
}

- (void)adapterManager:(MPBannerAdapterManager *)manager didLoadAd:(UIView *)ad
{
    _loading = NO;

    if (_adActionInProgress) {
        self.nextAdContentView = ad;
    } else {
        [self.adView setAdContentView:ad];
        [manager requestedAdDidBecomeVisible];
        [self scheduleAutorefreshTimerIfEnabled];

        if ([[self adViewDelegate] respondsToSelector:@selector(adViewDidLoadAd:)]) {
            [[self adViewDelegate] adViewDidLoadAd:[self adView]];
        }
    }
}

- (void)adapterManager:(MPBannerAdapterManager *)manager didRefreshAd:(UIView *)ad
{
    [self.adView setAdContentView:ad];
    [self scheduleAutorefreshTimerIfEnabled];

    if ([[self adViewDelegate] respondsToSelector:@selector(adViewDidLoadAd:)]) {
        [[self adViewDelegate] adViewDidLoadAd:[self adView]];
    }
}

- (void)adapterManager:(MPBannerAdapterManager *)manager didFailToLoadAdWithError:(MPError *)error
{
    _loading = NO;

    if ([error code] == MPErrorNoInventory) {
        [self scheduleAutorefreshTimerIfEnabled];
        if ([[self adViewDelegate] respondsToSelector:@selector(adViewDidFailToLoadAd:)]) {
            [[self adViewDelegate] adViewDidFailToLoadAd:[self adView]];
        }
    } else {
        [self loadAdWithURL:self.failoverURL];
    }
}

- (void)adapterManagerUserActionWillBegin:(MPBannerAdapterManager *)manager
{
    _adActionInProgress = YES;

    if ([self.autorefreshTimer isScheduled] && [self.autorefreshTimer isValid]) {
        [self.autorefreshTimer pause];
    }

    if ([[self adViewDelegate] respondsToSelector:@selector(willPresentModalViewForAd:)]) {
        [[self adViewDelegate] willPresentModalViewForAd:[self adView]];
    }
}

- (void)adapterManagerUserActionDidFinish:(MPBannerAdapterManager *)manager
{
    _adActionInProgress = NO;

    if (self.nextAdContentView) {
        [self.adView setAdContentView:self.nextAdContentView];
        self.nextAdContentView = nil;
        [manager requestedAdDidBecomeVisible];
        [self scheduleAutorefreshTimerIfEnabled];
    } else if ([self.autorefreshTimer isScheduled] && [self.autorefreshTimer isValid]) {
        [self.autorefreshTimer resume];
    }

    if ([[self adViewDelegate] respondsToSelector:@selector(didDismissModalViewForAd:)]) {
        [[self adViewDelegate] didDismissModalViewForAd:[self adView]];
    }
}

- (void)adapterManagerUserWillLeaveApplication:(MPBannerAdapterManager *)manager
{
    // XXX:
    _adActionInProgress = NO;

    if ([[self adViewDelegate] respondsToSelector:@selector(willLeaveApplicationFromAd:)]) {
        [[self adViewDelegate] willLeaveApplicationFromAd:[self adView]];
    }
}

#pragma mark - Custom Events (Deprecated)

- (void)customEventDidLoadAd
{
    [_adapterManager customEventDidLoadAd];

    _loading = NO;
    [self scheduleAutorefreshTimerIfEnabled];
}

- (void)customEventDidFailToLoadAd
{
    [_adapterManager customEventDidFailToLoadAd];

    _loading = NO;
    [self loadAdWithURL:self.failoverURL];
}

- (void)customEventActionWillBegin
{
    [_adapterManager customEventActionWillBegin];
}

- (void)customEventActionDidEnd
{
    [_adapterManager customEventActionDidEnd];
}

@end
