//
//  NSURLRequest+IgnoreSSL.m
//  tencentOAuthDemo
//
//  Created by JeaminW on 13-5-20.
//
//

#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}

@end
