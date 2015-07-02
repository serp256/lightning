//
//  SPLogLevel.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#ifndef SponsorPaySDK_SPLogLevel_h
#define SponsorPaySDK_SPLogLevel_h

typedef NS_ENUM(NSUInteger, SPLogLevel) {
    SPLogLevelVerbose = 0,
    SPLogLevelDebug = 10,
    SPLogLevelInfo = 20,
    SPLogLevelWarn = 30,
    SPLogLevelError = 40,
    SPLogLevelFatal = 50,
    SPLogLevelOff = 60
};

#endif
