//
//  addAlbumViewController.h
//  sdkDemo
//
//  Created by xiaolongzhang on 13-5-3.
//  Copyright (c) 2013年 xiaolongzhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DropDown;

@protocol DropDownDelegate <NSObject>
@optional

- (void)DropDown:(DropDown *)dropDown selectIndex:(NSInteger)index;

@end

//借助热心网友的代码实现的下拉菜单 代码来自http://blog.163.com/ytrtfhj@126/blog/static/8905310920116224445195/
@interface DropDown : UIView <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    UITableView *_tv;           //下拉列表
    NSArray *_tableArray;       //下拉输入框
    UITextField *_textField;    //文本输入框
    BOOL _showList;             //是否弹出下拉列表
    CGFloat _tableHeight;       //table下拉列表的高度
    CGFloat _frameHeight;       //frame的高度
}

@property (nonatomic, retain) UITableView *tv;
@property (nonatomic, retain) NSArray *tableArray;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, assign) id<DropDownDelegate> delegate;
@property (nonatomic, assign) NSInteger selectIndex;

- (void)dropdown;
- (void)packup;
@end

@interface addAlbumViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, DropDownDelegate>
{
    UITextView *_albumTitle;
    UITextView *_albumDesc;
    DropDown *_albumPriv;
    UITextView *_albumQuestion;
    UITextView *_albumAnswer;
}

@end
