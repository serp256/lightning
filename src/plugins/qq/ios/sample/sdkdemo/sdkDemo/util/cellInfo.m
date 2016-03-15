//
//  cellInfo.m
//  sdkDemo
//
//  Created by xiaolongzhang on 13-7-3.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import "cellInfo.h"

@implementation cellInfo

+ (cellInfo *)info:(NSString *)title target:(id)target Sel:(SEL)sel viewController:(id)viewController
{
    cellInfo *info = [[cellInfo alloc] init];
    info.title = title;
    info.target = target;
    info.sel = sel;
    info.viewController = viewController;
    info.userInfo = nil;
    return info;
}

+ (cellInfo *)info:(NSString *)title target:(id)target Sel:(SEL)sel viewController:(UIViewController *)viewController userInfo:(NSDictionary *)userInfo
{
    cellInfo *info = [[cellInfo alloc] init];
    info.title = title;
    info.target = target;
    info.sel = sel;
    info.viewController = viewController;
    info.userInfo = userInfo;
    return info;
}


@synthesize title = _title;
@synthesize target = _target;
@synthesize sel = _sel;
@synthesize viewController = _viewController;
@synthesize userInfo = _userInfo;
@end
