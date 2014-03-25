//
//  ALAdSize.h
//  sdk
//
//  Created by Basil on 2/27/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * This class defines a size of an ad to be displayed. It is recommended to use default sizes that are
 * declared in this class (<code>BANNER</code>, <code>INTERSTITIAL</code>)
 *  
 * @author Basil Shikin, Matt Szaro
 * @version 1.1
 */
@interface ALAdSize : NSObject<NSCopying> {
    NSUInteger width;
    NSUInteger height;
    NSString * label;
}

// Retrieve an appropriate singleton object representing a given ad size.
+(ALAdSize *) sizeBanner;
+(ALAdSize *) sizeInterstitial;
+(ALAdSize *) sizeMRec;
+(ALAdSize *) sizeLeader;

// Retrieve an array of all ad sizes
+(NSArray *) allSizes;

// Get dimensions and label of an ALAdSize object.
-(NSUInteger) width;
-(NSUInteger) height;
-(NSString *) label;

/*
 Get a reference to an ad size with a given string label - for example, "BANNER".
 If the given string does not correspond to a size that the SDK can handle,
 fall back to a given default size.
 */
+(ALAdSize*) sizeWithLabel: (NSString*) label orDefault: (ALAdSize*) defaultSize;

/* The methods below manually initialize an ad size. This shouldn't be used in most circumstances,
 as an unrecognized ad size could cause no fill. */

-(id)initWith: (NSString *)label;
-(id)initWith: (NSUInteger)width by:(NSUInteger)height;


@end
