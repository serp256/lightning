//
//  MPURLResolver.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPURLResolver.h"
#import "NSURL+MPAdditions.h"

@interface MPURLResolver ()

@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, assign) id<MPURLResolverDelegate> delegate;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *responseData;

@end

@implementation MPURLResolver

@synthesize URL = _URL;
@synthesize delegate = _delegate;

+ (MPURLResolver *)resolver
{
    return [[[MPURLResolver alloc] init] autorelease];
}

- (void)dealloc
{
    self.URL = nil;
    self.connection = nil;
    self.responseData = nil;

    [super dealloc];
}

- (void)startResolvingWithURL:(NSURL *)URL delegate:(id<MPURLResolverDelegate>)delegate
{
    [self.connection cancel];

    self.URL = URL;
    self.delegate = delegate;
    self.responseData = [NSMutableData data];

    if (![self handleURL:self.URL]) {
        self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.URL] delegate:self];
    }
}

- (void)cancel
{
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark - Handling Application/StoreKit URLs

- (BOOL)handleURL:(NSURL *)URL
{
    if ([self storeItemIdentifierForURL:URL]) {
        [self.delegate showStoreKitProductWithParameter:[self storeItemIdentifierForURL:URL] fallbackURL:URL];
    } else if ([self URLShouldOpenInApplication:URL]) {
        if ([[UIApplication sharedApplication] canOpenURL:URL]) {
            [self.delegate openURLInApplication:URL];
        } else {
            [self.delegate failedToResolveURLWithError:[NSError errorWithDomain:@"com.mopub" code:-1 userInfo:nil]];
        }
    } else {
        return NO;
    }

    return YES;
}

#pragma mark Identifying Application URLs

- (BOOL)URLShouldOpenInApplication:(NSURL *)URL
{
    return ![self URLIsHTTPOrHTTPS:URL] || [self URLPointsToAMap:URL];
}

- (BOOL)URLIsHTTPOrHTTPS:(NSURL *)URL
{
    return [URL.scheme isEqualToString:@"http"] || [URL.scheme isEqualToString:@"https"];
}

- (BOOL)URLPointsToAMap:(NSURL *)URL
{
    return [URL.host hasSuffix:@"maps.google.com"] || [URL.host hasSuffix:@"maps.apple.com"];
}


#pragma mark Extracting StoreItem Identifiers

- (NSString *)storeItemIdentifierForURL:(NSURL *)URL
{
    NSString *itemIdentifier = nil;
    if ([URL.host hasSuffix:@"itunes.apple.com"]) {
        NSString *lastPathComponent = [[URL path] lastPathComponent];
        if ([lastPathComponent hasPrefix:@"id"]) {
            itemIdentifier = [lastPathComponent substringFromIndex:2];
        } else {
            itemIdentifier = [URL.mp_queryAsDictionary objectForKey:@"id"];
        }
    } else if ([URL.host hasSuffix:@"phobos.apple.com"]) {
        itemIdentifier = [URL.mp_queryAsDictionary objectForKey:@"id"];
    }

    NSCharacterSet *nonIntegers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if (itemIdentifier && itemIdentifier.length > 0 && [itemIdentifier rangeOfCharacterFromSet:nonIntegers].location == NSNotFound) {
        return itemIdentifier;
    }

    return nil;
}

#pragma mark - <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if ([self handleURL:request.URL]) {
        [connection cancel];
        return nil;
    } else {
        self.URL = request.URL;
        return request;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *HTMLString = [[[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding] autorelease];
    [self.delegate showWebViewWithHTMLString:HTMLString
                                     baseURL:self.URL];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate failedToResolveURLWithError:error];
}

@end
