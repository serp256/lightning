//
//
// Copyright (c) 2015 Fyber. All rights reserved.
//
//

/**
 *  Enum for setting the log output level
 */
typedef NS_ENUM(NSUInteger, FYBLogLevel) {
    FYBLogLevelOff     = 0,  // No logs
    FYBLogLevelDebug   = 10, // Log debug statements
    FYBLogLevelInfo    = 20, // Log information about the SDK's behaviour
    FYBLogLevelWarn    = 30, // Log non-critical disfunctionment
    FYBLogLevelError   = 40  // Log critical error only
};
