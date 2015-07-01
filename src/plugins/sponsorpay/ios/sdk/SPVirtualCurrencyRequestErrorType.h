//
//  SPVirtualCurrencyRequestErrorType.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

/**
 *  Type of error returned by the Virtual Currency Server
 */
typedef NS_ENUM(NSInteger, SPVirtualCurrencyRequestErrorType) {
    /**
     *  No error
     */
    NO_ERROR,
    /**
     *  Error due to the internet connection
     */
    ERROR_NO_INTERNET_CONNECTION,
    /**
     *  Invalid response received from the server
     */
    ERROR_INVALID_RESPONSE,
    /**
     *  Invalid response signature received from the server
     */
    ERROR_INVALID_RESPONSE_SIGNATURE,
    /**
     *  Server returned an error
     */
    SERVER_RETURNED_ERROR,
    /**
     *  Other type of error
     */
    ERROR_OTHER
};
