//
//  SPInterstitialResponseProcessor.m
//  SponsorPayTestApp
//
//  Created by David Davila on 27/10/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import "SPInterstitialResponse.h"
#import "SPInterstitialOffer.h"

NSString *const SPInterstitialResponseErrorDomain = @"SPInterstitialResponseErrorDomain";
const NSInteger SPInterstitialResponseConnectionFailedErrorCode = -1;
const NSInteger SPInterstitialResponseResponseContainedErrorCode = -2;
const NSInteger SPInterstitialErrorParsingResponseErrorCode = -3;
const NSInteger SPInterstitialResponseUnknownErrorCode = -10;

NSString *const SPInterstitialResponseErrorLoggableDescriptionKey = @"SPInterstitialResponseErrorLoggableDescriptionKey";


@interface SPInterstitialResponse()
@property (strong, nonatomic) NSURLResponse *URLResponse;
@property (strong, nonatomic) id responseJSON;
@property (strong, nonatomic) NSError *connectionError;
@property (strong, nonatomic) NSError *invalidJSONResponseError;

@end

@implementation SPInterstitialResponse
{
    NSArray *_orderedOffers;
}

+ (instancetype)responseWithURLResponse:(NSURLResponse *)response
                                   data:(NSData *)data
                        connectionError:(NSError *)connectionError
{
    return [[self alloc] initWithURLResponse:response data:data connectionError:connectionError];
}

- (id)initWithURLResponse:(NSURLResponse *)response
                     data:(NSData *)data
          connectionError:(NSError *)connectionError
{
    self = [super init];
    if (self) {
        self.URLResponse = response;
        self.connectionError = connectionError;
        [self _parseResponseWithData:data];
    }

    return self;
}

- (void)_parseResponseWithData:(NSData *)data
{
    if (!self.connectionError) {
        NSError *error = nil;
        self.responseJSON = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&error];
        self.invalidJSONResponseError = error;
    }
}

- (BOOL)isSuccessResponse
{
    if (self.error) {
        return NO;
    }

    return YES;
}

- (NSError *)error
{
    if (self.connectionError) {
        return [self errorWithCode:SPInterstitialResponseConnectionFailedErrorCode
                       description:@"Connection to the SponsorPay backend failed"
                   underlyingError:self.connectionError];
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.URLResponse;
    if (httpResponse.statusCode > 299 || httpResponse.statusCode < 200) {
        return [self errorWithCode:SPInterstitialResponseResponseContainedErrorCode
                       description:[NSString stringWithFormat:@"Response contains HTTP error code=%d",
                                    httpResponse.statusCode]];
    }

    if (self.invalidJSONResponseError) {
        return [self errorWithCode:SPInterstitialErrorParsingResponseErrorCode
                       description:@"Response was malformed"
                   underlyingError:self.invalidJSONResponseError];
    }

    if (![self responseHasExpectedStructure]) {
        return [self errorWithCode:SPInterstitialErrorParsingResponseErrorCode
                       description:@"Response has unexpected structure"];
    }

    // From here on, things that never should go wrong actually
    if (!self.URLResponse) {
        return [self errorWithCode:SPInterstitialResponseUnknownErrorCode
                       description:@"Empty URL Response"];
    }

    if (![self.URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        return [self errorWithCode:SPInterstitialResponseUnknownErrorCode
                       description:@"URLResponse is not NSHTTPURLResponse"];
    }

    return nil;
}

- (NSError *)errorWithCode:(NSInteger)code
               description:(NSString *)description
{
    return [self errorWithCode:code description:description underlyingError:nil];
}

- (NSError *)errorWithCode:(NSInteger)code
               description:(NSString *)description
           underlyingError:(NSError *)underlyingError
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{SPInterstitialResponseErrorLoggableDescriptionKey:description}];

    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }

    return [NSError errorWithDomain:SPInterstitialResponseErrorDomain
                               code:code
                           userInfo:userInfo];
}

- (BOOL)responseHasExpectedStructure
{
    if (![self.responseJSON isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSArray *responseItems = [self responseItems];
    BOOL invalidItemFound = NO;

    for (id element in responseItems) {
        if (![element isKindOfClass:[NSDictionary class]]) {
            invalidItemFound = YES;
            break;
        }
    }
    return !invalidItemFound;
}

- (NSArray *)responseItems
{
    NSDictionary *responseRoot = self.responseJSON;
    return responseRoot[@"ads"];
}

- (NSArray *)orderedOffers
{
    if (![self responseHasExpectedStructure]) {
        return nil;
    }

    NSArray *offerItems = [self responseItems];
    NSMutableArray *parsedOffers = [NSMutableArray arrayWithCapacity:offerItems.count];

    for (NSDictionary *offerItem in offerItems) {
        NSString *networkName = offerItem[@"provider_type"];
        NSString *adId = offerItem[@"ad_id"];
        NSDictionary *offerExtras = offerItem;
        [parsedOffers addObject:[SPInterstitialOffer offerWithNetworkName:networkName
                                                                     adId:adId
                                                           arbitraryData:offerExtras]];
    }

    return parsedOffers;
}

@end
