//
//  weiyunViewController.h
//  sdkDemo
//
//  Created by xiaolongzhang on 13-7-3.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    kWeiyunPhoto,
    kWeiyunMusic,
    kWeiyunVideo,
    kWeiyunRecord,
}
WeiyunType;

@interface weiyunViewController : UITableViewController

@property (nonatomic, assign)WeiyunType type;

@end
