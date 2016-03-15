//
//  NSData+HexAdditions.h
//  sdkDemo
//
//  Created by xiaolongzhang on 13-6-27.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NSData_HexAdditions)

+ (NSData *)dataFromHex16String:(NSString *)hex16Str;

-(NSString *)stringWithHexBytes1;
-(NSString *)stringWithHexBytes2;

-(NSString *)digest;
-(NSString *)md5;
@end
