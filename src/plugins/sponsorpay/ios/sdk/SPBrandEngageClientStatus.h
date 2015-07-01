//
//  SPBrandEngageClientStatus.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef SponsorPaySDK_SPBrandEngageClientStatus_h
#define SponsorPaySDK_SPBrandEngageClientStatus_h

/** These constants are used to refer to the different states an engagement can be in. */
typedef NS_ENUM(NSInteger, SPBrandEngageClientStatus) {
    /// The BrandEngage player's underlying content has been loaded and the engagement has started.
    STARTED,

    /// The engagement has finished after completing. User will be rewarded.
    CLOSE_FINISHED,

    /// The engagement has finished before completing.
    /// The user might have aborted it, either explicitly (by tapping the close button) or
    /// implicitly (by switching to another app) or it was interrupted by an asynchronous event
    /// like an incoming phone call.
    CLOSE_ABORTED,

    /// The engagement was interrupted by an error.
    ERROR
};

#endif
