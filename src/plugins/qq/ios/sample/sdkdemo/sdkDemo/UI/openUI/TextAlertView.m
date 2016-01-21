//
//  TextAlertView.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-4-1.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "TextAlertView.h"

@implementation TextAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)layoutSubviews{
    
    CGRect rect = self.bounds;
    rect.size.height += 40;
    self.bounds = rect;
    float maxLabelY = 0.f;
    int textFieldIndex = 0;
    for (UIView *view in self.subviews) {
        
        if ([view isKindOfClass:[UIImageView class]])
        {
            
        }
        else if ([view isKindOfClass:[UILabel class]])
        {
            rect = view.frame;
            maxLabelY = rect.origin.y + rect.size.height;
        }
        else if ([view isKindOfClass:[UITextField class]])
        {
            rect = view.frame;
            rect.size.width = self.bounds.size.width - 2*10;
            rect.size.height = 30;
            rect.origin.x = 10;
            rect.origin.y = maxLabelY + 10*(textFieldIndex+1) + 30*textFieldIndex;
            view.frame = rect;
            textFieldIndex++;
        }
        else
        {
            rect = view.frame;
            rect.origin.y = self.bounds.size.height - 65.0;
            view.frame = rect;
        }
    }
    
}
@end
