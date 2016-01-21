//
//  RequestContentViewController.h
//  tencentOAuthDemo
//
//  Created by xiaolongzhang on 13-6-14.
//
//

#import <UIKit/UIKit.h>
#import "YIPopupTextView.h"
#import <TencentOpenAPI/TencentMessageObject.h>

@interface RequestContentViewController : UITableViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate, YIPopupTextViewDelegate,UIAlertViewDelegate>

@property (nonatomic, retain)NSArray *dataSource;
@property (nonatomic, retain)TencentApiReq *req;

@end
