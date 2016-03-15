//
//  RootViewController.h
//  TimerScroller
//
//  Created by Andrew Carter on 12/4/11.

#import <UIKit/UIKit.h>

#import "TimeScroller.h"

@interface photoListViewController : UIViewController <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, TimeScrollerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UITableView *_tableView;
    TimeScroller *_timeScroller;
    UIActivityIndicatorView *_activityIndicatorView;
    BOOL _isLoading;
    BOOL _isScrolling;
}

@property (nonatomic, retain)NSArray *photoInfoArray;
@property (nonatomic, retain)NSString *albumId;

@end
