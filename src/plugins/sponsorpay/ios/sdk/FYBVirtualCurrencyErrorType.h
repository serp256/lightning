//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

#import <Foundation/Foundation.h>

/**
 *  Type of error returned by the Virtual Currency servers
 */
typedef NS_ENUM(NSInteger, FYBVirtualCurrencyErrorType) {
//TODO: Remove when wrapper is deprecated
    FYBVirtualCurrencyErrorTypeNoError,                  // No error
    FYBVirtualCurrencyErrorTypeNoConnection,             // Error due to the internet connection
    FYBVirtualCurrencyErrorTypeInvalidResponse,          // Invalid response received from the server
    FYBVirtualCurrencyErrorTypeInvalidResponseSignature, // Invalid response signature received from the server
    FYBVirtualCurrencyErrorTypeServer,                   // Server returned an error
    FYBVirtualCurrencyErrorTypeOther                     // Other type of error
};
