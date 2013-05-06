//
//  MPAdDestinationDisplayAgent.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "MPAdDestinationDisplayAgent.h"
#import "MPGlobal.h"
#import "UIViewController+MPAdditions.h"
#import "MPInstanceProvider.h"

@interface MPAdDestinationDisplayAgent ()

@property (nonatomic, retain) MPURLResolver *resolver;
@property (nonatomic, assign) BOOL inUse;
@property (nonatomic, assign) id<MPAdDestinationDisplayAgentDelegate> delegate;

- (void)presentStoreKitControllerWithItemIdentifier:(NSString *)identifier fallbackURL:(NSURL *)URL;

@end

@implementation MPAdDestinationDisplayAgent

@synthesize delegate = _delegate;
@synthesize resolver = _resolver;

+ (MPAdDestinationDisplayAgent *)agentWithDelegate:(id<MPAdDestinationDisplayAgentDelegate>)delegate
{
    MPAdDestinationDisplayAgent *agent = [[[MPAdDestinationDisplayAgent alloc] init] autorelease];
    agent.delegate = delegate;
    agent.resolver = [[MPInstanceProvider sharedProvider] buildMPURLResolver];
    return agent;
}

- (void)dealloc
{
    self.resolver = nil;
    [super dealloc];
}

- (void)displayDestinationForURL:(NSURL *)URL
{
    if (self.inUse) return;
    self.inUse = YES;

    [MPProgressOverlayView presentOverlayInWindow:MPKeyWindow()
                                         animated:MP_ANIMATED
                                         delegate:self];
    [self.delegate displayAgentWillPresentModal];

    [self.resolver startResolvingWithURL:URL delegate:self];
}

#pragma mark - <MPURLResolverDelegate>

- (void)showWebViewWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)URL
{
    [self hideOverlay];

    MPAdBrowserController *browser = [[[MPAdBrowserController alloc] initWithURL:URL
                                                                      HTMLString:HTMLString
                                                                        delegate:self] autorelease];
    browser.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [[self.delegate viewControllerForPresentingModalView] mp_presentModalViewController:browser
                                                                               animated:MP_ANIMATED];
}

- (void)showStoreKitProductWithParameter:(NSString *)parameter fallbackURL:(NSURL *)URL
{
    if ([MPStoreKitProvider deviceHasStoreKit]) {
        [self presentStoreKitControllerWithItemIdentifier:parameter fallbackURL:URL];
    } else {
        [self openURLInApplication:URL];
    }
}

- (void)openURLInApplication:(NSURL *)URL
{
    [self hideOverlay];
    [self.delegate displayAgentWillLeaveApplication];

    [[UIApplication sharedApplication] openURL:URL];
    self.inUse = NO;
}

- (void)failedToResolveURLWithError:(NSError *)error
{
    [self hideOverlay];
    [self.delegate displayAgentDidDismissModal];
    self.inUse = NO;
}

- (void)presentStoreKitControllerWithItemIdentifier:(NSString *)identifier fallbackURL:(NSURL *)URL
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_6_0
    SKStoreProductViewController *controller = [MPStoreKitProvider buildController];
    controller.delegate = self;

    NSDictionary *parameters = [NSDictionary dictionaryWithObject:identifier
                                                           forKey:SKStoreProductParameterITunesItemIdentifier];
    [controller loadProductWithParameters:parameters completionBlock:nil];

    [self hideOverlay];
    [[self.delegate viewControllerForPresentingModalView] mp_presentModalViewController:controller
                                                                               animated:MP_ANIMATED];
#endif
}

#pragma mark - <MPSKStoreProductViewControllerDelegate>
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self hideModalAndNotifyDelegate];
    self.inUse = NO;
}

#pragma mark - <MPAdBrowserControllerDelegate>
- (void)dismissBrowserController:(MPAdBrowserController *)browserController animated:(BOOL)animated
{
    [self hideModalAndNotifyDelegate];
    self.inUse = NO;
}

#pragma mark - <MPProgressOverlayViewDelegate>
- (void)overlayCancelButtonPressed
{
    [self.resolver cancel];
    [self hideOverlay];
    [self.delegate displayAgentDidDismissModal];
    self.inUse = NO;
}

#pragma mark - Convenience Methods
- (void)hideModalAndNotifyDelegate
{
    [[self.delegate viewControllerForPresentingModalView] mp_dismissModalViewControllerAnimated:MP_ANIMATED];
    [self.delegate displayAgentDidDismissModal];
}

- (void)hideOverlay
{
    [MPProgressOverlayView dismissOverlayFromWindow:MPKeyWindow() animated:MP_ANIMATED];
}


@end
