//
//  ALAdType.h
//  sdk
//
//  Created by Matt Szaro on 10/1/13.
//
//

#import <Foundation/Foundation.h>

/*
 ALAdType is a new concept that compliments ALAdSize.
 
 While ALAdSize refers to the dimensions of the ad - banner, inter, etc - ALAdType
 refers to some distinguishing characteristic of the ad, if it is exposed to the
 developer differently than a standard ad (ALAdTypeStandard, as in ALInterstitalAd/ALAdView).
 
 Currently the only special ALAdType is ALAdTypeIncentivized, which refers to ads requested
 through ALIncentivizedInterstitialAd.
 */

@interface ALAdType : NSObject <NSCopying>

-(id)initWithLabel: (NSString *) label;
-(NSString*) label;

+(ALAdType *) adTypeFromString: (NSString*) adType;

+(ALAdType*) typeRegular;
+(ALAdType*) typeIncentivized;
+(NSArray*) allTypes;

@end
