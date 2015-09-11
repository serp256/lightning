//
//  SPConstants.h
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 08/11/13.
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPConstants : NSObject

// Interstitial Event Notification constants
FOUNDATION_EXPORT NSString *const SPInterstitialEventNotification;

FOUNDATION_EXPORT NSString *const SPUrlGeneratorRequestIDKey;
FOUNDATION_EXPORT NSString *const SPUrlGeneratorPlacementIDKey;
FOUNDATION_EXPORT NSString *const SPUrlGeneratorTimestampKey;

// Exceptions names
FOUNDATION_EXPORT NSString *const SPExceptionInvalidUserId;
FOUNDATION_EXPORT NSString *const SPExceptionNoCredentials;

// MBE Constants
FOUNDATION_EXPORT NSString *const SPRequestValidate;

// VCS
FOUNDATION_EXPORT NSString *const SPCurrencyNameChangeNotification;
FOUNDATION_EXPORT NSString *const SPNewCurrencyNameKey;
FOUNDATION_EXPORT NSString *const SPCurrencyNameConfigKey;

// SPSchemeParser

FOUNDATION_EXPORT NSString *const SPCustomURLScheme;

FOUNDATION_EXPORT NSString *const SPRequestOffersAnswer;
FOUNDATION_EXPORT NSString *const SPRequestInstall;
FOUNDATION_EXPORT NSString *const SPRequestExit;
FOUNDATION_EXPORT NSString *const SPRequestValidate;
FOUNDATION_EXPORT NSString *const SPRequestPlay;
FOUNDATION_EXPORT NSString *const SPRequestStartStatus;
FOUNDATION_EXPORT NSString *const SPRequestShowOfferwall;
FOUNDATION_EXPORT NSString *const SPRequestUserData;

FOUNDATION_EXPORT NSString *const SPRequestInstallAppId;
FOUNDATION_EXPORT NSString *const SPRequestInstallUserId;
FOUNDATION_EXPORT NSString *const SPRequestInstallPlacementId;
FOUNDATION_EXPORT NSString *const SPRequestInstallAffiliateToken;
FOUNDATION_EXPORT NSString *const SPRequestInstallCampaignToken;
FOUNDATION_EXPORT NSString *const SPRequestURLParameterKey;
FOUNDATION_EXPORT NSString *const SPRequestStatusParameterKey;
FOUNDATION_EXPORT NSString *const SPThirtPartyNetworkParameter;
FOUNDATION_EXPORT NSString *const SPNumberOfOffersParameterKey;

FOUNDATION_EXPORT NSString *const SPTPNLocalName;
FOUNDATION_EXPORT NSString *const SPTPNShowAlertParameter;
FOUNDATION_EXPORT NSString *const SPTPNAlertMessageParameter;
FOUNDATION_EXPORT NSString *const SPTPNTrackingURLParameter;
FOUNDATION_EXPORT NSString *const SPTPNClickThroughURL;
FOUNDATION_EXPORT NSString *const SPIDParameter;

@end
