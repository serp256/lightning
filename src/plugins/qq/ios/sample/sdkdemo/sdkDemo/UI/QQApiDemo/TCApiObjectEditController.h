//
//  TCApiObjectEditController.h
//  tencentOAuthDemo
//
//  Created by JeaminWong on 13-3-18.
//
//

#import <UIKit/UIKit.h>

@class TCApiObjectEditController;

typedef void(^TCApiObjectEditDoneHandler)(TCApiObjectEditController *editCtrl);
typedef void(^TCApiObjectEditCancelHandler)(TCApiObjectEditController *editCtrl);

@interface TCApiObjectEditController : UIViewController<UITextViewDelegate,UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITextField *objTitle;
@property (retain, nonatomic) IBOutlet UITextView *objDesc;
@property (retain, nonatomic) IBOutlet UITextView *objText;
@property (retain, nonatomic) IBOutlet UITextView *objUrl;
@property (retain, nonatomic) NSArray *imgDataArray;

- (void)modalIn:(UIViewController*)parentCtrl withDoneHandler:(TCApiObjectEditDoneHandler)doneHandler cancelHandler:(TCApiObjectEditCancelHandler)cancelHandler animated:(BOOL)animated;

@end
