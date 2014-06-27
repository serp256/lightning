//
//  AppLovinAd.h
//  sdk
//
//  Created by Basil on 2/27/12.
//  Copyright (c) 2013, AppLovin Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALAdSize.h"
#import "ALAdType.h"

/**
 * This class represents an ad that has been served from AppLovin server and
 * should be displayed to the user.
 *
 * @author Basil Shikin, Matt Szar
 * @version 1.2
 */
@interface ALAd : NSObject <NSCopying>

@property (strong, nonatomic) ALAdSize * size;
@property (strong, nonatomic) ALAdType * adType;
@property (strong, nonatomic) NSString * videoUrl;
@property (strong, nonatomic) NSString * html;
@property (strong, nonatomic) NSArray  * destinationUrls;

@end
