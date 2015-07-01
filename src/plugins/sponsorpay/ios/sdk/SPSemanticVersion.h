//
//  SPSemVer.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 27/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Semantic version helper
 */
@interface SPSemanticVersion : NSObject

@property (nonatomic, assign, readonly) NSInteger major;
@property (nonatomic, assign, readonly) NSInteger minor;
@property (nonatomic, assign, readonly) NSInteger patch;

+ (instancetype)versionWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch;

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch;

- (BOOL)isEqualTo:(SPSemanticVersion *)aVersion;
- (BOOL)isGreaterThan:(SPSemanticVersion *)aVersion;
- (BOOL)isLessThan:(SPSemanticVersion *)aVersion;

@end
