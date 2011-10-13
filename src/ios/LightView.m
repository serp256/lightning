//
//  EAGLView.m
//  Sparrow
//
//  Created by Daniel Sperl on 13.03.09.
//  Copyright 2009 Incognitek. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "LightView.h"
#import "mlwrapper_ios.h"

// --- private interface ---------------------------------------------------------------------------

@interface LightView ()

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) id displayLink;

- (void)setup;
//- (void)createFramebuffer;
- (void)destroyFramebuffer;

- (void)renderStage;
-(void)resizeFramebuffer;
//- (void)processTouchEvent:(UIEvent*)event;

@end

// --- class implementation ------------------------------------------------------------------------

@implementation LightView

#define REFRESH_RATE 60

//@synthesize stage = mStage;
@synthesize timer = mTimer;
@synthesize displayLink = mDisplayLink;
@synthesize frameRate = mFrameRate;

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
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:@"3.1" options:NSNumericSearch] != NSOrderedAscending) mDisplayLinkSupported = YES;
    
		self.multipleTouchEnabled = YES;
    self.frameRate = 60.0f;
    
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
    
		CGRect rect = self.frame;
		mStage = mlstage_create(rect.size.width - rect.origin.x,rect.size.height - rect.origin.y);
}

- (void)layoutSubviews 
{
    [self resizeFramebuffer];
    [self renderStage];        // fill buffer immediately to avoid flickering
}

-(void)resizeFramebuffer
{
	glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
	[mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mHeight);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) NSLog(@"failed to create framebuffer: %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	mlstage_resize(mStage,mWidth,mHeight);
}

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

    mlstage_advanceTime(mStage,timePassed);

    mLastFrameTimestamp = now;
    
    [EAGLContext setCurrentContext:mContext];
    
    glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
    
    mlstage_render(mStage);
    
    glBindRenderbuffer(GL_RENDERBUFFER, mRenderbuffer);
    [mContext presentRenderbuffer:GL_RENDERBUFFER];
    
		[pool release];
}

- (void)setTimer:(NSTimer *)newTimer 
{    
    if (mTimer != newTimer)
    {
        [mTimer invalidate];        
        mTimer = newTimer;
    }
}

- (void)setDisplayLink:(id)newDisplayLink
{
    if (mDisplayLink != newDisplayLink)
    {
        [mDisplayLink invalidate];
        mDisplayLink = newDisplayLink;
    }
}

- (void)setFrameRate:(float)value
{    
    if (mDisplayLinkSupported)
    {
        int frameInterval = 1;            
        while (REFRESH_RATE / frameInterval > value)
            ++frameInterval;
        mFrameRate = REFRESH_RATE / frameInterval;
    }
    else 
        mFrameRate = value;
    
    if (self.isStarted)
    {
        [self stop];
        [self start];
    }
}

- (BOOL)isStarted
{
    return mTimer || mDisplayLink;
}

- (void)start
{
    if (self.isStarted) return;
    if (mFrameRate > 0.0f)
    {
        mLastFrameTimestamp = CACurrentMediaTime();
        
				if (mDisplayLinkSupported)
        {
            mDisplayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(renderStage)];
						[mDisplayLink setFrameInterval: (int)(REFRESH_RATE / mFrameRate)];
						[mDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else 
        {
            // timer used as a fallback
            self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / mFrameRate) target:self selector:@selector(renderStage) userInfo:nil repeats:YES];            
        }
    }
}

- (void)stop
{
    [self renderStage]; // draw last-moment changes
    
    self.timer = nil;
    self.displayLink = nil;
}

+ (Class)layerClass 
{
    return [CAEAGLLayer class];
}

//#define PROCESS_TOUCH_EVENT if (self.isStarted && mLastTouchTimestamp != event.timestamp) { process_touches(self,touches,event,mStage); mLastTouchTimestamp = event.timestamp; }    
#define PROCESS_TOUCH_EVENT if (self.isStarted) process_touches(self,touches,event,mStage);

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event 
{   
	PROCESS_TOUCH_EVENT;
} 

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{	
	PROCESS_TOUCH_EVENT;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	PROCESS_TOUCH_EVENT;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{    
    mLastTouchTimestamp -= 0.0001f; // cancelled touch events have an old timestamp -> workaround
    PROCESS_TOUCH_EVENT;
}

/*
- (void)processTouchEvent:(UIEvent*)event
{
	PROCESS_TOUCH_EVENT;
}
*/

- (void)dealloc 
{    
    if ([EAGLContext currentContext] == mContext) 
        [EAGLContext setCurrentContext:nil];
    
    [mContext release];
		mlstage_destroy(mStage);
    //[mRenderSupport release];
    [self destroyFramebuffer];
    
    self.timer = nil;       // invalidates timer    
    self.displayLink = nil; // invalidates displayLink        
    
    [super dealloc];
}

@end
