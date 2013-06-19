//
//  SPMBEWebView.h
//  SponsorPay Mobile Brand Engage SDK
//
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSPMBEStartOfferTimeout (NSTimeInterval)10.0

#define kSPMBEWebViewJavascriptErrorDomain @"kSPMBEWebViewJavascriptErrorDomain"

@class SPBrandEngageWebView;

@protocol SPBrandEngageWebViewDelegate <NSObject>

@required
- (void)brandEngageWebView:(SPBrandEngageWebView *) BEWebView
  javascriptReportedOffers:(int)numberOfOffers;
- (void)brandEngageWebViewJavascriptOnStarted:(SPBrandEngageWebView *) BEWebView;
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView didFailWithError:(NSError *)error;
- (void)brandEngageWebViewOnAborted:(SPBrandEngageWebView *) BEWebView;
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
      requestsToCloseFollowingOfferURL:(NSURL *)url;

@end

@interface SPBrandEngageWebView : UIWebView <UIWebViewDelegate>

@property (assign) id<SPBrandEngageWebViewDelegate> brandEngageDelegate;

- (void)startOffer;
- (void)park;

@end
