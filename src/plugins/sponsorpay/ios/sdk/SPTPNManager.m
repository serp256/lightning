//
//  SPProviderManager.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 30/12/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPBaseNetwork.h"
#import "SPTPNManager.h"
#import "SPLogger.h"
#import "SPSemanticVersion.h"

static NSString *const SPAdaptersKey = @"SPNetworks";
static NSString *const SPNetworkName = @"SPNetworkName";
static NSString *const SPNetworkSuffix = @"SPNetworkSuffix";
static NSString *const SPNetworkParameters = @"SPNetworkParameters";

static const NSInteger SPAdapterSupportedVersion = 2;

@interface SPTPNManager()

@property (strong, nonatomic) NSMutableDictionary *networks;

@end

@implementation SPTPNManager

#pragma mark - Class methods
+ (instancetype)sharedInstance
{
    static SPTPNManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPTPNManager alloc] init];
    });
    return sharedInstance;
}

+ (void)startNetworks:(NSArray*)networks
{
    [[self sharedInstance] startNetworks:networks];
}

+ (id<SPTPNVideoAdapter>)getRewardedVideoAdapterForNetwork:(NSString *)networkName
{
    return [[self sharedInstance] getRewardedVideoAdapterForNetwork:networkName];
}

+ (NSArray *)getAllRewardedVideoAdapters
{
    return [[self sharedInstance] getAllRewardedVideoAdapters];
}

+ (id<SPInterstitialNetworkAdapter>)getInterstitialAdapterForNetwork:(NSString *)networkName
{
    return [[self sharedInstance] getInterstitialAdapterForNetwork:networkName];
}

+ (NSArray *)getAllInterstitialAdapters
{
    return [[self sharedInstance] getAllInterstitialAdapters];
}

#pragma mark - Instance methods
- (instancetype)init
{
    self = [super init];
    if (self) {
        _networks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)startNetworks:(NSArray*)ntwks
{
    NSArray *networks = ntwks ? ntwks : [[NSBundle mainBundle] infoDictionary][SPAdaptersKey];
    [networks enumerateObjectsUsingBlock:^(id providerData, NSUInteger idx, BOOL *stop) {
        NSString *networkName = providerData[SPNetworkName];
        NSString *networkClassName = [self getClassName:networkName];

        Class NetworkClass = NSClassFromString(networkClassName);
        if (!NetworkClass) {
            SPLogError(@"Class %@ could not be found", networkClassName);
            return;
        }

        if ([self isAdapterAlreadyRegistered:NetworkClass]) {
            SPLogError(@"Provider %@ is already registered", networkName);
            return;
        }

        if (![NetworkClass isSubclassOfClass:[SPBaseNetwork class]]) {
            SPLogError(@"Class %@ is not a subclass of %@", NSStringFromClass(NetworkClass), NSStringFromClass([SPBaseNetwork class]));
            return;
        }

        if (![self isAdapterVersionValid:[NetworkClass adapterVersion]]) {
            SPLogError(@"Could not add %@: Adapter version is %@ but this SDK version support only adapters with version %d.X.X", networkName, [NetworkClass adapterVersion], SPAdapterSupportedVersion);
            return;
        }

        SPBaseNetwork *network = [[NetworkClass alloc] init];
        // Starts the SDK and Adapters
        BOOL sdkStarted = [network startNetworkWithName:networkName data:providerData[SPNetworkParameters]];

        if (!sdkStarted) {
            return;
        }

        [self.networks setObject:network forKey:[network.name lowercaseString]];
    }];
}

- (id<SPTPNVideoAdapter>)getRewardedVideoAdapterForNetwork:(NSString *)networkName
{
    SPBaseNetwork *network = self.networks[[networkName lowercaseString]];
    if (network.supportedServices & SPNetworkSupportRewardedVideo) {
        return [network rewardedVideoAdapter];
    } else {
        return nil;
    }
}

- (NSArray *)getAllRewardedVideoAdapters
{
    __block NSMutableArray *videoAdapters = [[NSMutableArray alloc] init];
    NSArray *networks = [self.networks allValues];
    [networks enumerateObjectsUsingBlock:^(SPBaseNetwork *network, NSUInteger idx, BOOL *stop) {
        if ([network supportedServices] & SPNetworkSupportRewardedVideo ) {
            [videoAdapters addObject:[network rewardedVideoAdapter]];
        }
    }];
    return [NSArray arrayWithArray:videoAdapters];
}

- (id<SPInterstitialNetworkAdapter>)getInterstitialAdapterForNetwork:(NSString *)networkName
{
    SPBaseNetwork *network = self.networks[[networkName lowercaseString]];
    if (network.supportedServices & SPNetworkSupportInterstitial) {
        return [network interstitialAdapter];
    } else {
        return nil;
    }
}

- (NSArray *)getAllInterstitialAdapters
{
    __block NSMutableArray *interstitialAdapters = [[NSMutableArray alloc] init];
    NSArray *networks = [self.networks allValues];
    [networks enumerateObjectsUsingBlock:^(SPBaseNetwork *network, NSUInteger idx, BOOL *stop) {
        if ([network supportedServices] & SPNetworkSupportInterstitial) {
            [interstitialAdapters addObject:[network interstitialAdapter]];
        }
    }];
    return [NSArray arrayWithArray:interstitialAdapters];
}

#pragma mark - Helper Methods

- (BOOL)isAdapterAlreadyRegistered:(__unsafe_unretained Class)networkClass
{
    // Checks if the provider is already integrated. Since we won't reuse networks, we can check if an object of the network class exists in the networks
    // Also, sometimes the provider.name is different than suffix used to instantiate the class
    NSArray *integratedNetworks = [self.networks allValues];
    NSUInteger index = [integratedNetworks indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj class] == networkClass) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        return NO;
    }
    return YES;
}

// The adapter's major version reflects the version of the interface between the sdk <-> adapter.
- (BOOL)isAdapterVersionValid:(SPSemanticVersion *)adapterVersion
{
    return adapterVersion.major == SPAdapterSupportedVersion;
}

// Gets the provider class name by concatenating the name.
- (NSString *)getClassName:(NSString *)networkName
{
    NSString *trimmedNetworkName = [networkName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *networkClassName = [NSString stringWithFormat:@"SP%@Network", trimmedNetworkName];
    return networkClassName;
}

@end
