//
//  SPCountdownView.m
//  testCountdownView
//
//  Created by Daniel Barden on 17/03/14.
//  Copyright (c) 2014 SponsorPay GmbH. All rights reserved.
//

#import "SPCountdownView.h"
#import "SPLogger.h"
#import <QuartzCore/QuartzCore.h>

#define IS_RETINA() [[UIScreen mainScreen] scale] == 2.0

typedef NS_ENUM(NSInteger, SPCountdownViewState){
    SPCountdownViewStateNotStarted,
    SPCountdownViewStatePlaying,
    SPCountdownViewStatePaused,
};

static const NSTimeInterval SPUpdateInterval = 0.1;

@interface SPCountdownView ()

@property (strong, nonatomic) NSTimer *progressTimer;
@property (assign, nonatomic) SPCountdownViewState state;
@property (assign, nonatomic) NSTimeInterval countdownProgress;
@end

@implementation SPCountdownView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    CGPoint centerPoint = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:centerPoint
                                                              radius:self.frame.size.width / 2
                                                          startAngle:(3 * M_PI) / 2
                                                            endAngle:-(M_PI)/2 clockwise:NO];

    if (!self.innerCircleLayer) {
        CAShapeLayer *innerCircleLayer = [CAShapeLayer layer];

        [innerCircleLayer setPath:[circlePath CGPath]];
        innerCircleLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        self.innerCircleLayer = innerCircleLayer;
        [self.layer addSublayer:innerCircleLayer];
    }

    if (!self.outerCircleLayer) {
        // Outer Circle
        CAShapeLayer *outerCircleLayer = [CAShapeLayer layer];
        [outerCircleLayer setPath:[circlePath CGPath]];

        outerCircleLayer.lineWidth = IS_RETINA() ? 0.7 : 1.5;

        outerCircleLayer.fillColor = [UIColor clearColor].CGColor;
        outerCircleLayer.strokeColor = [UIColor whiteColor].CGColor;
        self.outerCircleLayer = outerCircleLayer;
        [self.layer addSublayer:outerCircleLayer];
    }

    if (!self.countdownLabel) {
        UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
        label.textColor = [UIColor colorWithWhite:1 alpha:0.7];
        self.countdownLabel = label;
        [self addSubview:label];
    }
}

- (void)play
{
    switch (self.state) {
        case SPCountdownViewStateNotStarted:
            [self start];
            break;
        case SPCountdownViewStatePaused:
            [self resume];
            break;
        default:
            break;
    }
}

- (void)start
{
    if (!self.outerCircleLayer.superlayer) {
        [self.layer addSublayer:self.outerCircleLayer];
    }
    SPLogDebug(@"Starting animation with duration %f", self.duration);
    self.countdownProgress = self.duration;
    self.state = SPCountdownViewStatePlaying;
    self.countdownLabel.text = [NSString stringWithFormat:@"%.f", self.duration];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:SPUpdateInterval target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];

    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = self.duration;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.removedOnCompletion = NO;
    [self.outerCircleLayer addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
}

- (void)pause
{
    self.state = SPCountdownViewStatePaused;
    CFTimeInterval pausedTime = [self.outerCircleLayer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.outerCircleLayer.speed = 0.0;
    self.outerCircleLayer.timeOffset = pausedTime;
    [self.progressTimer invalidate];
}

- (void)resume
{
    self.state = SPCountdownViewStatePlaying;
    CFTimeInterval pausedTime = self.outerCircleLayer.timeOffset;
    self.outerCircleLayer.speed = 1.0;
    self.outerCircleLayer.timeOffset = 0.0;
    self.outerCircleLayer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.outerCircleLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.outerCircleLayer.beginTime = timeSincePause;

    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:SPUpdateInterval target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
}

- (void)updateCountdownWithTimeInterval:(NSTimeInterval)timeInterval
{
    if (timeInterval > self.duration) {
        return;
    }

    self.countdownProgress = self.duration - timeInterval;
}

- (void)updateCountdown
{
    self.countdownProgress -= SPUpdateInterval;
    double roundedCountdownProgress = round(self.countdownProgress);
    double boundedCountdownProgress = roundedCountdownProgress > 0 ? roundedCountdownProgress : 0;
    self.countdownLabel.text = [NSString stringWithFormat:@"%.f", boundedCountdownProgress];

    // I think it can happen that updateCountdown is called a bit after SPUpdateInterval is due,
    // which would explain edge cases where countdownProgress gets a small negative value we need to guard against.
    if (self.countdownProgress - SPUpdateInterval < 0) {
        self.state = SPCountdownViewStateNotStarted;
        [self.progressTimer invalidate];
        [self.outerCircleLayer removeFromSuperlayer];
    }
}
@end
