//
//  SPCloseButton.m
//  SPVideoPlayer
//
//  Created by Daniel Barden on 29/01/14.
//  Copyright (c) 2014 SponsorPay GmbH. All rights reserved.
//

#import "SPCloseButton.h"
#import <QuartzCore/QuartzCore.h>

#define IS_RETINA() [[UIScreen mainScreen] scale] == 2.0

@interface SPCloseButton ()

@end

@implementation SPCloseButton

- (id)initWithFrame:(CGRect)frame paddingInsets:(UIEdgeInsets)insets
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _paddingInsets = insets;
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame paddingInsets:UIEdgeInsetsZero];
}

- (void)setupView
{
    CGFloat lineWidth = IS_RETINA() ? 0.7 : 1.5;

    CGColorRef strokeColor = [UIColor colorWithWhite:1 alpha:0.7].CGColor;
    CGPoint centerPoint = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    CGRect drawableArea = UIEdgeInsetsInsetRect(self.bounds, self.paddingInsets);
    CGFloat radius = drawableArea.size.width / 2;

    CAShapeLayer *backgroundCircleLayer = [CAShapeLayer layer];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:centerPoint
                                                              radius:radius
                                                          startAngle:- (M_PI / 2)
                                                            endAngle:(3 * M_PI)/2 clockwise:YES];

    backgroundCircleLayer.path = circlePath.CGPath;
    backgroundCircleLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    backgroundCircleLayer.strokeColor = strokeColor;
    backgroundCircleLayer.lineWidth = lineWidth;

    self.backgroundLayer = backgroundCircleLayer;
    [self.layer addSublayer:backgroundCircleLayer];

    // The X of the close button
    CGFloat xLengthRatio = 0.5;
    CAShapeLayer *x = [CAShapeLayer layer];
    x.lineWidth = lineWidth;
    UIBezierPath *xPath = [UIBezierPath bezierPath];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x, centerPoint.y + (radius * xLengthRatio))];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x, centerPoint.y - (radius * xLengthRatio))];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x + (radius * xLengthRatio), centerPoint.y)];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x - (radius * xLengthRatio), centerPoint.y)];
    [xPath moveToPoint:centerPoint];
    [xPath closePath];

    x.strokeColor = strokeColor;
    x.path = xPath.CGPath;
    [backgroundCircleLayer addSublayer:x];
    [self setTransform:CGAffineTransformMakeRotation(M_PI_4)];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.backgroundLayer.fillColor = [UIColor colorWithWhite:127/255.0 alpha:0.5].CGColor;
    } else {
        self.backgroundLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    }
    [super setHighlighted:highlighted];
}

@end
