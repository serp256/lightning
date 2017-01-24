//
//
// Copyright (c) 2016 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "FYBInterstitialCreativeType.h"

@interface FYBInterstitialOffer : NSObject

@property (nonatomic, copy, readonly) NSString *networkName;
@property (nonatomic, copy, readonly) NSString *adId;
@property (nonatomic, copy, readonly) NSString *tpnPlacementId;
@property (nonatomic, assign, readonly) FYBInterstitialCreativeType creativeType;
@property (nonatomic, strong, readonly) NSDictionary *trackingParams;

+ (FYBInterstitialOffer *)interstitialOfferWithDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
