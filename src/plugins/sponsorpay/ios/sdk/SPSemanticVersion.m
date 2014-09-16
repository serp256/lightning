//
//  SPSemVer.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 27/02/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPSemanticVersion.h"

@interface SPSemanticVersion()

@property (assign, nonatomic, readwrite) NSInteger major;
@property (assign, nonatomic, readwrite) NSInteger minor;
@property (assign, nonatomic, readwrite) NSInteger patch;

@end

@implementation SPSemanticVersion

+ (instancetype)versionWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch
{
    return [[SPSemanticVersion alloc] initWithMajor:major minor:minor patch:patch];
}

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch
{
    self = [super init];
    if (self) {
        _major = major;
        _minor = minor;
        _patch = patch;
    }
    return self;
}

- (NSComparisonResult)compare:(SPSemanticVersion *)aVersion
{
    if (!aVersion) {
		[[NSException exceptionWithName:NSInvalidArgumentException reason:@"Comparing against a nil argument" userInfo:nil] raise];
	}

    NSComparisonResult result = [@(self.major) compare:@(aVersion.major)];
	if (result != NSOrderedSame) {
		return result;
	}

	result = [@(self.minor) compare:@(aVersion.minor)];
	if (result != NSOrderedSame) {
		return result;
	}

	result = [@(self.patch) compare:@(aVersion.patch)];
	if (result != NSOrderedSame) {
		return result;
	}

    return NSOrderedSame;
}

- (BOOL)isEqualTo:(SPSemanticVersion *)aVersion
{
    return [self compare:aVersion] == NSOrderedSame;
}

- (BOOL)isLessThan:(SPSemanticVersion *)aVersion
{
    return [self compare:aVersion] == NSOrderedAscending;
}

- (BOOL)isGreaterThan:(SPSemanticVersion *)aVersion
{
    return [self compare:aVersion] == NSOrderedDescending;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d.%d.%d", self.major, self.minor, self.patch];
}

@end
