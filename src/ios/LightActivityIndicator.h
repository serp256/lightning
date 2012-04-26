//
//  ActivityIndicatorController.h
//  SmartCheat
//
//  Created by Yury Lasty on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LightActivityIndicatorView : UIAlertView <UIAlertViewDelegate> {
    UIActivityIndicatorView * activity;
}
-(id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
-(void)show;
@end



