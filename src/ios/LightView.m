//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "LightView.h"
#import "mlwrapper_ios.h"
#import <CoreMotion/CMAccelerometer.h>
#import "motion.h"
#import "mobile_res.h"
#import "LightViewController.h"

// --- private interface ---------------------------------------------------------------------------

@interface LightView ()

@property (nonatomic, retain) id displayLink;

- (void)setup;
//- (void)createFramebuffer;
- (void)destroyFramebuffer;

- (void)renderStage;
//-(void)resizeFramebuffer;
//- (void)processTouchEvent:(UIEvent*)event;

@end

// --- class implementation ------------------------------------------------------------------------

@implementation LightView

#define REFRESH_RATE 60 // This is 

//@synthesize stage = mStage;
@synthesize displayLink = mDisplayLink;

- (id)initWithFrame:(CGRect)frame 
{    
    if ([super initWithFrame:frame]) 
    {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    if ([super initWithCoder:decoder]) 
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    NSLog(@"setup LightView");
    if (mContext) return; // already initialized!
    
    // A system version of 3.1 or greater is required to use CADisplayLink.
    //NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    //if ([currSysVer compare:@"3.1" options:NSNumericSearch] != NSOrderedAscending) mDisplayLinkSupported = YES;

		if ([self respondsToSelector:@selector(contentScaleFactor)]) {
			[self setContentScaleFactor:[UIScreen mainScreen].scale];
		};
    
		self.multipleTouchEnabled = YES;
    //self.frameRate = 30.0f;
    
    // get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, 
        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];    

    mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];    
    if (!mContext || ![EAGLContext setCurrentContext:mContext]) NSLog(@"Could not create render context");    

    glGenFramebuffers(1, &mFramebuffer);
    glGenRenderbuffers(1, &mRenderbuffer);

		NSLog(@"Buffers: %d:%d",mFramebuffer,mRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mRenderbuffer);
		[mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mWidth);
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mHeight);
		NSLog(@"glsize: %d:%d",mWidth,mHeight);

		char* index_bpath = bundle_path("index");
		NSLog(@"index_bpath %s", index_bpath);

		if (index_bpath == nil) {
			NSLog(@"resources index file not found");
			caml_failwith("resources index file not found");
		}

		FILE* res_indx = fopen(index_bpath, "r");
		read_res_index(res_indx, 0, -1);
		fclose(res_indx);

		mStage = mlstage_create(mWidth,mHeight);
}

/*
- (void)layoutSubviews 
{
		NSLog(@"Layout subviews");
    [self resizeFramebuffer];
		if (mStage != NULL) {
		  mlstage_resize(mStage,mWidth,mHeight);	
		} else {
		  mStage = mlstage_create(mWidth,mHeight);		  
		};
    mLastFrameTimestamp = CACurrentMediaTime();
    [self renderStage]; // fill buffer immediately to avoid flickering

		NSLog(@"end of layoutSubviews");
}
*/
/*
-(void)resizeFramebuffer
{
	glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
	[mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mHeight);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) NSLog(@"failed to create framebuffer: %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
}
*/

- (void)destroyFramebuffer 
{
    glDeleteFramebuffers(1, &mFramebuffer);
    mFramebuffer = 0;
    glDeleteRenderbuffers(1, &mRenderbuffer);
    mRenderbuffer = 0;    
}

- (void)renderStage
{
	if (mFramebuffer == 0 || mRenderbuffer == 0) {
		NSLog(@"buffers not yet initialized");
		return; // buffers not yet initialized
	}


	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	double now = CACurrentMediaTime();
	double timePassed = now - mLastFrameTimestamp;

	/*
		 if (mDisplayLink) {
		 NSLog(@"frameInerval: %d, duration: %f, timestamp: %f, timePassed: %f",[mDisplayLink frameInterval],[mDisplayLink duration],[mDisplayLink timestamp],timePassed);
		 } else {
		 NSLog(@"DisplayLink is NIL");
		 }*/

	/* 
		 mlstage_advanceTime(mStage,timePassed);
		 mLastFrameTimestamp = now;
		 [EAGLContext setCurrentContext:mContext];
		 glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
		 mlstage_render(mStage);
		 glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
		 [mContext presentRenderbuffer:GL_RENDERBUFFER];
		 */
	//caml_acquire_runtime_system();

	//printf("lastupTime: %f; now: %f; now - accLastUpTime: %f; accUpInterval: %f\n", accLastUpTime, now, now - accLastUpTime, accUpInterval);

	if (accEnabled && (now - accLastUpTime >= accUpInterval)) {
		acmtrGetData(now);
	}

	mlstage_advanceTime(mStage,timePassed);
	// prerender here
	mlstage_preRender();
	mLastFrameTimestamp = now;
	[EAGLContext setCurrentContext:mContext];
	glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
	restore_default_viewport();
	
	if (mlstage_render(mStage)) {
		glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
		[mContext presentRenderbuffer:GL_RENDERBUFFER];		
	}
	//caml_release_runtime_system();
	[pool release];
}

/*
- (void)setTimer:(NSTimer *)newTimer 
{    
    if (mTimer != newTimer)
    {
        [mTimer invalidate];        
        mTimer = newTimer;
    }
}
*/

/*
- (void)setDisplayLink:(id)newDisplayLink
{
	if (mDisplayLink != newDisplayLink)
	{
		[mDisplayLink invalidate];
		mDisplayLink = newDisplayLink;
	}
}
*/

/*- (void)setFrameRate:(float)value
{    
	int frameInterval = 1;            
	while (REFRESH_RATE / frameInterval > value) ++frameInterval;
	mFrameRate = REFRESH_RATE / frameInterval;
	if (self.isStarted)
	{
		// FIXME!!!!
		//[self stop];
		//[self start];
	}
}*/

- (BOOL)isStarted
{
    //return mTimer || mDisplayLink;
		return (mDisplayLink != nil && !mDisplayLink.paused);
}

- (void)start
{
	NSLog(@"START view");
	if (!mDisplayLink) {
		int frameRate = mlstage_getFrameRate(mStage);
		NSLog(@"frameRate: %d",frameRate);
		if (frameRate > REFRESH_RATE) frameRate = REFRESH_RATE;
		else if (frameRate < 1) frameRate = 1;
		mDisplayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(renderStage)];
		[mDisplayLink setFrameInterval: (int)(REFRESH_RATE / frameRate)];
		[mDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		mLastFrameTimestamp = CACurrentMediaTime();
    	[self renderStage];
    NSLog(@"mLastFrameTimestamp %f", mLastFrameTimestamp);
	} else mDisplayLink.paused = NO;
	/*caml_acquire_runtime_system();
	mlstage_start(mStage);
	caml_release_runtime_system();*/
	flushErrlog();
}

- (void)stop
{
	NSLog(@"STOP View");
	if (!mDisplayLink) return;
	mDisplayLink.paused = YES;
	//self.displayLink = nil;
	/*caml_acquire_runtime_system();
	mlstage_stop(mStage);
	caml_release_runtime_system();*/
}

-(void)background 
{
	//caml_acquire_runtime_system();
	mlstage_background();
}

-(void)foreground
{
	mlstage_foreground();
	//caml_release_runtime_system();
}

+ (Class)layerClass 
{
	return [CAEAGLLayer class];
}

//#define PROCESS_TOUCH_EVENT if (self.isStarted && mLastTouchTimestamp != event.timestamp) { process_touches(self,touches,event,mStage); mLastTouchTimestamp = event.timestamp; }    
//#define PROCESS_TOUCH_EVENT if (self.isStarted) {
#define PROCESS_TOUCH_EVENT \
	NSAssert(!processTouchesInProgress,@"PROCESS TOUCH EVENT while processTouchesInProgress"); \
	processTouchesInProgress = YES; \
	process_touches(self,touches,event,mStage);\
	processTouchesInProgress = NO;

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event 
{   
	//NSLog(@"touches Began");
	PROCESS_TOUCH_EVENT;
} 

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{	
	//NSLog(@"touches Moved");
	PROCESS_TOUCH_EVENT;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	//NSLog(@"touches Ended");
	PROCESS_TOUCH_EVENT;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{    
	//NSLog(@"touches Cancelled");
    mLastTouchTimestamp -= 0.0001f; // cancelled touch events have an old timestamp -> workaround
		if (processTouchesInProgress) {
			NSLog(@"TOuch in progress, needCacnelAllTouches");
			mStage->needCancelAllTouches = 1;
		} else PROCESS_TOUCH_EVENT;
}

/*
- (void)processTouchEvent:(UIEvent*)event
{
	PROCESS_TOUCH_EVENT;
}
*/

- (void)dealloc 
{    
		[mDisplayLink invalidate];
    mDisplayLink = nil; 

		mlstage_destroy(mStage);

    if ([EAGLContext currentContext] == mContext) [EAGLContext setCurrentContext:nil];
    
    [mContext release];
    //[mRenderSupport release];
    [self destroyFramebuffer];
    
    //self.timer = nil;       // invalidates timer    
    
    [super dealloc];
}

@end
