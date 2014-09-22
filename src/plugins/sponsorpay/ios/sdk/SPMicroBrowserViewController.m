//
//  SPMicroBrowserViewController.m
//  SponsorPayTestApp
//
//  Created by Daniel Barden on 22/03/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPMicroBrowserViewController.h"
#import "SPLogger.h"

@interface SPMicroBrowserViewController () <UIWebViewDelegate>

@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIWebView *webView;

@end

@implementation SPMicroBrowserViewController

- (id)init
{
    self = [super init];
    if (self) {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _webView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    // Navigation Bar
    self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
    self.navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Navigation Bar Title
    UINavigationItem *navItem = [UINavigationItem alloc];
    navItem.title = @"Loading...";
    [self.navBar pushNavigationItem:navItem animated:NO];

    // Navigation Bar Done Button
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(closeView)];

    self.navBar.topItem.leftBarButtonItem = barButtonItem;

    // UIWebview
    self.webView.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 44.0, self.view.frame.size.width, self.view.frame.size.height);
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.webView];
    [self.view addSubview:self.navBar];
}

- (void)loadRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

#pragma mark - UIWebView delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *navBarTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    SPLogDebug(@"Setting window tite to %@", navBarTitle);
    if (navBarTitle.length) {
        self.navBar.topItem.title = navBarTitle;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    SPLogDebug(@"%@", [error localizedDescription]);
}

#pragma mark - UINavigation actions
- (void)closeView
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate microBrowserDidClose:self];
    }];
}

#pragma mark - Geometry related methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

@end
