//
//  SPNetworkVideoAdapter.h
//  SponsorPaySDK
//
//  Copyright (c) 2013 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SPRewardedVideoNetworkAdapter;
@class SPBaseNetwork;

/**
 * Defines the interface of a delegate object through which a class implementing
 * the SPVideoNetworkAdapter protocol will communicate back with the SponsorPay SDK.
 */
@protocol SPRewardedVideoNetworkAdapterDelegate<NSObject>

@required

/**
 * Tells the delegate about the availability of videos from the wrapped video network,
 * as a response to the [SPVideoNetworkAdapterDelegate checkAvailability] invocation.
 */
- (void)adapter:(id<SPRewardedVideoNetworkAdapter>)adapter didReportVideoAvailable:(BOOL)available;

/**
 * Tells the delegate that the wrapped video network SDK started playing a video.
 */
- (void)adapterVideoDidStart:(id<SPRewardedVideoNetworkAdapter>)adapter;
/**
 * Tells the delegate that the wrapped video network SDK aborted the playing of
 * a video due to user action.
 */
- (void)adapterVideoDidAbort:(id<SPRewardedVideoNetworkAdapter>)adapter;

/**
 * Tells the delegate that the wrapped video network SDK played a video until
 * its completion.
 */
- (void)adapterVideoDidFinish:(id<SPRewardedVideoNetworkAdapter>)adapter;

/**
 * Tells the delegate that the wrapped video network SDK closed the video player /
 * post video screen and relinquished control of the user flow.
 */
- (void)adapterVideoDidClose:(id<SPRewardedVideoNetworkAdapter>)adapter;

/**
 * Tells the delegate that an error occurred while the wrapped SDK was checking for
 * available videos or attempting to play a video.
 */
- (void)adapter:(id<SPRewardedVideoNetworkAdapter>)adapter didFailWithError:(NSError *)error;

/**
 * Tells the delegate that the wrapped SDK didn't respond timely to the command
 * to start playing a video, and will not play. It is typically not needed to
 * invoke this delegate method unless the wrapped SDK doesn't always start playing
 * immediately when requested.
 */
- (void)adapterDidTimeout:(id<SPRewardedVideoNetworkAdapter>)adapter;

@end

/**
 * Defines the interface required by a video network SDK wrapper.
 */
@protocol SPRewardedVideoNetworkAdapter<NSObject>

/**
 * Delegate implementing the SPVideoNetworkAdapterDelegate protocol that will get notified of
 * events in the lifecycle of the network adapter.
 */
@property (weak) id<SPRewardedVideoNetworkAdapterDelegate> delegate;

/**
 * Returns the name of the wrapped video network.
 */
- (NSString *)networkName;

/**
 * Initializes the SDK with the given data
 */
- (BOOL)startAdapterWithDictionary:(NSDictionary *)dict;

/**
 * Checks whether there are videos available to start playing. This is expected
 * to be asynchronous, and the answer should be delivered through the
 * -adapter:didReportVideoAvailable: delegate method.
 */
- (void)checkAvailability;

/**
 * Instructs the wrapped video network SDK to start playing a video.
 *
 * @param parentVC If the wrapped SDK needs a parent UIViewController to which attach its own video player view controller to, it can use the provided one.
 */
- (void)playVideoWithParentViewController:(UIViewController *)parentVC;

- (void)setNetwork:(SPBaseNetwork *)network;

@end