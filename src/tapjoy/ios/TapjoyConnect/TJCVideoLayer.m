// Copyright (C) 2011-2012 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license


#import "TJCVideoLayer.h"
#import "TJCVideoView.h"
#import "TJCUtil.h"
#import "TJCVideoObject.h"
#import "TJCVideoManager.h"
#import "TJCVideoRequestHandler.h"
#import "TJCUIWebPageView.h"


@implementation TJCVideoLayer

@synthesize closeButton = closeButton_,
videoFeed = videoFeed_,
isVideoPlaying = isVideoPlaying_,
fileName = fileName_,
linkURLString = linkURLString_,
offerID = offerID_,
isFinishedWatching = isFinishedWatching_,
shouldDisplayLogo = shouldDisplayLogo_,
webView = webView_;


- (void)setVideoView:(UIView*)view
{
	[self setFrame:view.bounds];
	[videoFeed_.view setFrame:view.bounds];
	[completeScreenView_ setFrame:view.bounds];
	[completeScreenView_ setBackgroundColor:[UIColor clearColor]];
	[webView_ refreshWithFrame:view.bounds];
	[webView_ setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
	[self addSubview:videoFeed_.view];
	
	[self addSubview:completeScreenView_];
	
	[self addSubview:statusLabel_];
	[self bringSubviewToFront:statusLabel_];
	[self addSubview:tapjoyLogo_];
	[self bringSubviewToFront:tapjoyLogo_];
	[self addSubview:closeButton_];
	[self bringSubviewToFront:closeButton_];
	
	// Initially, the web view will not be visible.
	[completeScreenView_ setAlpha:0];
}


- (void)refreshViewWithBounds:(CGRect)bounds
{
	[self setFrame:bounds];
	[videoFeed_.view setFrame:bounds];
	[completeScreenView_ setFrame:bounds];
	[completeScreenView_ setBackgroundColor:[UIColor clearColor]];
	[webView_ setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
}


- (IBAction)transitionToWebView
{
	[completeScreenView_ setAlpha:1];
	[self bringSubviewToFront:completeScreenView_];
	
	[doneButton_ setAlpha:0];
}


- (IBAction)transitionToVideoView
{
	[completeScreenView_ setAlpha:0];
	[self sendSubviewToBack:completeScreenView_];
	
	[doneButton_ setAlpha:1];
}


- (void)prepareVideoWithDelegate:(id<TJCVideoAdDelegate>)delegate videoURL:(NSString*)URLString shouldStream:(BOOL)shouldStream
{
	delegate_ = delegate;
	
	isVideoPlaying_ = YES;
	
	
	NSURL *contentURL = nil;
	if (shouldStream)
	{
		// Load from a link, for streaming.
		contentURL = [NSURL URLWithString:URLString];
	}
	else
	{
		// Load locally from the device.
		contentURL = [NSURL fileURLWithPath:URLString];
	}
	
	// Init the video
	if (videoFeed_)
	{
		[videoFeed_ release];
	}
	videoFeed_ = [[MPMoviePlayerController alloc] initWithContentURL:contentURL];
	[videoFeed_ setControlStyle:MPMovieControlStyleNone];
	[videoFeed_ setShouldAutoplay:NO];
	// Disables any type of unwanted touch events.
	[videoFeed_.view setUserInteractionEnabled:NO];
	
	// Init the web view.
	if (!webView_)
	{
		// Default window frame, is changed later in setVideoView.
		webView_ = [[TJCUIWebPageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	}
	[webView_ setDelegate:self];
	[webView_ setViewToTransparent:NO];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
														  selector:@selector(movieDurationAvailable:)
																name:MPMovieDurationAvailableNotification
															 object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
														  selector:@selector(movieDidFinishWatching:)
																name:MPMoviePlayerPlaybackDidFinishNotification
															 object:nil];
	
	didIconDownload_ = NO;
	didLogoDownload_ = NO;
}


- (void)enableShowVideoCompleteScreen:(BOOL)enable
{
	if (enable)
	{
		// Fade in view only if not visible.
		if (completeScreenView_.alpha < 1)
		{
			[completeScreenView_ setAlpha:0];
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:TJC_VIDEO_STATUS_TEXT_FADE_DURATION];
			[completeScreenView_ setAlpha:1];
		}
	}
	else
	{
		// Fade out view only if visible.
		if (completeScreenView_.alpha > 0)
		{
			[completeScreenView_ setAlpha:1];
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:TJC_VIDEO_STATUS_TEXT_FADE_DURATION];
			[completeScreenView_ setAlpha:0];
		}
	}
	
	[UIView commitAnimations];
}


- (void)enableShowStatusLabel:(BOOL)enable
{
	if (enable)
	{
		[statusLabel_ setAlpha:0];
		[tapjoyLogo_ setAlpha:0];
		[closeButton_ setAlpha:0];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:TJC_VIDEO_STATUS_TEXT_FADE_DURATION];
		[statusLabel_ setAlpha:1];
		[closeButton_ setAlpha:1];
		if (shouldDisplayLogo_)
		{
			[tapjoyLogo_ setAlpha:1];
		}
		else
		{
			[tapjoyLogo_ setAlpha:0];
		}
	}
	else
	{
		// Get rid of status text.
		[statusLabel_ setAlpha:1];
		[tapjoyLogo_ setAlpha:1];
		[closeButton_ setAlpha:1];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:TJC_VIDEO_STATUS_TEXT_FADE_DURATION];
		[statusLabel_ setAlpha:0];
		[tapjoyLogo_ setAlpha:0];
		[closeButton_ setAlpha:0];
	}
	
	[UIView commitAnimations];
}


- (void)movieDurationAvailable:(id)sender
{
	duration_ = [videoFeed_ duration];
	//NSLog(@"Movie Duration:%f", duration_);
	NSString *statusStr = [NSString stringWithFormat:@"%d seconds left", (int)duration_];

	
	[statusLabel_ setText:statusStr];
}


- (void)movieDidFinishWatching:(NSNotification*)notification
{
	//MPMoviePlayerController *playerController = [notification object];
	//NSNumber *finishReason = [[notification userInfo] objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"];	
	//NSLog(@"VideoFinishReason: %@", finishReason);
	
	// Show video complete screen.
	[self enableShowVideoCompleteScreen:YES];
	
	// Disable timer status text.
	[self enableShowStatusLabel:NO];
	
	isVideoPlaying_ = NO;
	
	// Ping servers to notify that video has been completed, currency should be awarded.
	if (offerID_)
	{
		[[[TJCVideoManager sharedTJCVideoManager] requestHandler] requestVideoCompleteWithOfferID:offerID_];
		offerID_ = nil;
	}
	
	// Set video complete flag for special behavior when cancelling a video.
	isFinishedWatching_ = YES;
}


- (void)loadWebViewWithURL:(NSString*)URLString
{
	[webView_ loadURLRequest:URLString withTimeOutInterval:TJC_REQUEST_TIME_OUT];
}


- (void)playVideo
{
	[self enableShowVideoCompleteScreen:NO];

	// Stop and play from the beginning.
	//[videoFeed_ stop];
	[videoFeed_ play];
	
	// Fade status label in.
	[self enableShowStatusLabel:YES];
	
	// Start the tick to update the status text of the time remaining on the video.
	[NSTimer scheduledTimerWithTimeInterval:0.25f 
												target:self 
											 selector:@selector(updateStatusText:)
											 userInfo:nil 
											  repeats:YES];
	
	isVideoPlaying_ = YES;
	
	// Begin download of tapjoy logo.
	if (!didLogoDownload_)
	{
		NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self 
																										selector:@selector(loadLogoImage)
																										  object:nil];
		[queue addOperation:operation];
		[operation release];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
														  selector:@selector(movieDidFinishWatching:)
																name:MPMoviePlayerPlaybackDidFinishNotification
															 object:nil];
}


- (void)loadLogoImage
{
	// Now download Tapjoy logo, located in the lower right hand corner of the video.
	NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	// Set video file path.
	NSString *videoPath = [cachesDirectory stringByAppendingFormat:@"/VideoAds/watermark.png"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath])
	{
		NSURL *logoURL = [NSURL URLWithString:TJC_VIDEO_LOGO_IMAGE_URL];
		NSData *logoData = [[NSData alloc] initWithContentsOfURL:logoURL];
		UIImage *logoImg = [[[UIImage alloc] initWithData:logoData] autorelease];
		[logoData release];
		
		[self performSelectorOnMainThread:@selector(displayLogo:) withObject:logoImg waitUntilDone:NO];
	}
}


- (void)displayLogo:(UIImage*)logoImage
{
	didLogoDownload_ = YES;
	[tapjoyLogo_ setAlpha:0];
	
	[tapjoyLogo_ setImage:logoImage];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:TJC_VIDEO_STATUS_TEXT_FADE_DURATION];
	if (shouldDisplayLogo_)
	{
		[tapjoyLogo_ setAlpha:1];
	}
	else
	{
		[tapjoyLogo_ setAlpha:0];
	}
	[UIView commitAnimations];
}


- (void)enableLogo:(BOOL)enable
{
	shouldDisplayLogo_ = enable;
	
	// Never enable the logo in the video complete screen.
	if (!isVideoPlaying_)
	{
		return;
	}

	if (enable)
	{
		[tapjoyLogo_ setAlpha:1];
	}
	else
	{
		[tapjoyLogo_ setAlpha:0];
	}
}


- (void)stopVideo
{
	isVideoPlaying_ = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
	[videoFeed_ stop];
}


- (void)pauseVideo
{
	[videoFeed_ pause];
}


- (void)resumeVideo
{
	[videoFeed_ play];
}


- (void)cancelVideo
{
	[self stopVideo];
	
	// Show video complete screen.
	[self enableShowVideoCompleteScreen:YES];
	
	// Disable timer status text.
	[self enableShowStatusLabel:NO];
	
	isVideoPlaying_ = NO;
}


- (void)cleanupVideo
{	
	isVideoPlaying_ = NO;
	
	if (videoFeed_)
	{
		[videoFeed_ release];
		videoFeed_ = nil;
	}
	if (webView_)
	{
		// Clear web view content.
		[webView_ clearWebViewContents];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}


- (void)updateStatusText:(NSTimer*)timer
{
	// Stop the tick when we reach the end of the video.
	if ((duration_ - videoFeed_.currentPlaybackTime) < 0)
	{
		[timer invalidate];
	}
	
	NSString *statusStr = [NSString stringWithFormat:@"%d seconds left", (int)(duration_ - videoFeed_.currentPlaybackTime)];	

	[statusLabel_ setText:statusStr];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	//NSLog(@"URL host: %@", [[request URL] host]);
	
	if (!request)
	{
		return NO;
	}
	
	NSString *requestString = [[request URL] absoluteString];
	
	// Check for replay button click and showOffers click.
	if (requestString == nil)
	{
		// Error check. If the request string is null for some reason, do nothing.
		return NO;
	}
	else if (CFStringFind((CFStringRef)requestString, (CFStringRef)TJC_VIDEO_CLICK_PROTOCOL, kCFCompareCaseInsensitive).length > 0)
	{
		//[webView_ parseVideoClickURL:requestString shouldPlayVideo:NO];
		// Different code path since we need to skip some things when playing a video from a completion screen.
		[self playVideo];
		
		// Handled, return NO.
		return NO;
	}
	else if (CFStringFind((CFStringRef)requestString, (CFStringRef)@"offer_wall", kCFCompareCaseInsensitive).length > 0)
	{
		// This is gross, calling back up to the video view cause that's where closing the video view is handled.
		[[[TJCVideoManager sharedTJCVideoManager] videoView] closeVideoView];
		return NO;
	}

	// If we see either tapjoy or linkshare host names, we won't open it externally. All other host names will open externally from the app.
	if ((CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_TAPJOY_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_TAPJOY_ALT_HOST_NAME, kCFCompareCaseInsensitive).length > 0) ||
		 (CFStringFind((CFStringRef)[[request URL] host], (CFStringRef)TJC_LINKSHARE_HOST_NAME, kCFCompareCaseInsensitive).length > 0))
	{
		// Return YES here to indicate that we want to load the content.
		return YES;
	}
	
	// Open the link externally.
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[request URL]] 
																			  delegate:self 
																	startImmediately:YES];
	[conn release];

	return NO;
}


- (NSURLRequest*)connection:(NSURLConnection*)connection 
				willSendRequest:(NSURLRequest*)request 
			  redirectResponse:(NSURLResponse*)response
{
	[TJCLog logWithLevel:LOG_DEBUG format:@"OPENING EXTERNAL URL NOW ::::::%@", [request URL]];
	
	// Open up itunes. This will effectively place this app in the background.
	[[UIApplication sharedApplication] openURL:[request URL]];
	
	// Immediately cancel redirects since we only care about the first one.
	[connection cancel];
	
	// Returning nil will also ensure that we don't follow the redirects within the webview.
	// We rely on mobile safari to do so.
	return nil;
}


- (void)dealloc
{
	[offerID_ release];
	[completeScreenView_ release];
	[webView_ release];
	[videoFeed_ release];
	[closeButton_ release];
	[super dealloc];
}

@end
