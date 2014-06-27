//
//  SPNetworkParametersProvider.m
//  SponsorPay iOS SDK
//
//  Created by David Davila on 11/2/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPNetworkParametersProvider.h"
#import "SPReachability.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>


static NSString *const kSPURLParamKey_NetworkConnectionType = @"network_connection_type";
static NSString *const kSPURLParamValue_NetworkConnectionTypeCellular = @"cellular";
static NSString *const kSPURLParamValue_NetworkConnectionTypeWiFi = @"wifi";

static NSString *const kSPURLParamKey_CarrierName = @"carrier_name";
static NSString *const kSPURLParamKeyCarrierCountry = @"carrier_country";

@implementation SPNetworkParametersProvider

- (NSDictionary *)dictionaryWithKeyValueParameters
{
    NSString *connectionTypeValue = kSPURLParamValue_NetworkConnectionTypeWiFi;
    SPReachability *reachability = [SPReachability reachabilityForInternetConnection];
    SPNetworkStatus status = [reachability currentReachabilityStatus];
    if (status == SPReachableViaWWAN) {
        connectionTypeValue = kSPURLParamValue_NetworkConnectionTypeCellular;
    }

    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *currentCarrier = [networkInfo subscriberCellularProvider];

    NSString *currentCarrierName = @"", *currentCarrierISOCountryCode = @"";
    
    if (currentCarrier && currentCarrier.carrierName && currentCarrier.isoCountryCode) {
        currentCarrierName = currentCarrier.carrierName;
        currentCarrierISOCountryCode = currentCarrier.isoCountryCode;
    }
    
    NSDictionary *networkParameters = @{
    kSPURLParamKey_NetworkConnectionType : connectionTypeValue,
    kSPURLParamKey_CarrierName : currentCarrierName,
    kSPURLParamKeyCarrierCountry : currentCarrierISOCountryCode
    };
    
    return networkParameters;
}

@end
