//
//  NSURLRequest+IgnoreSSL.h
//  tencentOAuthDemo
//
//  Created by JeaminW on 13-5-20.
//
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host;

@end
