//
//  SPOfferWallStatus.h
//  SponsorPaySDK
//
//  Created by tito on 07/08/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

/**
 *  Status of the OfferWall when being dismissed
 */
typedef NS_ENUM(NSInteger, SPOfferWallStatus) {
    /**
     *  OfferWall was dismissed because of a network error
     */
    SPOfferWallStatusNetworkError = -1,
    /**
     *  OfferWall was dismissed because there was no offers
     */
    SPOfferWallStatusNoOffer,
    /**
     *  OfferWall was dismissed by the user
     */
    SPOfferWallStatusFinishedByUser
};

