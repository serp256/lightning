//
//  ViewController.h
//  QQApiInterfaceDemo
//
//  Created by Random Zhang on 12-5-16.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#if BUILD_QQAPIDEMO
#import "TencentOpenAPI/QQApiInterface.h"
#else
#define QQApiInterfaceDelegate NSObject
#endif

@interface QQApiDemoController : UIViewController<UITableViewDataSource,UITableViewDelegate,QQApiInterfaceDelegate,UIImagePickerControllerDelegate>
{
    UITableView* _operationTable;
    NSArray* _operationList;
    
    UIControl* _bkControl;
    UITextView* _titleControl;
    UITextView* _descControl;
    
    UILabel* _titleLabel;
    UILabel* _descLabel;
}
@end
