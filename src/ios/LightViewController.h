//
//  LightViewController.h
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <StoreKit/StoreKit.h>
#import <caml/mlvalues.h>
#import "LightActivityIndicator.h"

@protocol OrientationDelegate 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (BOOL)shouldAutorotate;
- (NSUInteger)supportedInterfaceOrientations;
@end

@interface LightViewController : UIViewController <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate, SKPaymentTransactionObserver> {
	id<OrientationDelegate> _orientationDelegate;
	LightActivityIndicatorView*	activityIndicator;
@public
	value payment_success_cb;
	value payment_error_cb;
	value remote_notification_request_success_cb;
	value remote_notification_request_error_cb;
}

+(LightViewController*)sharedInstance;
+(void)addExceptionInfo:(NSString*)info;
+(NSString *)version;
-(void)becomeActive;
-(void)resignActive;
-(void)background;
-(void)foreground;
-(void)showLeaderboard;
-(void)showAchievements;
-(void)showActivityIndicator:(LightActivityIndicatorView *)indicator;
-(void)hideActivityIndicator;
+(void)setSupportEmail:(NSString*)email;
- (void)showKeyboard:(value)visible size:(value)size  updateCallback:(value)updateCallback returnCallback:(value)returnCallback initString:(value)initString;

-(void)hideKeyboard;

@property (nonatomic,retain) id<OrientationDelegate> orientationDelegate;

@end

/* при модальном показе LightViewController паузит себя, однако он не знает, когда показываемый им контроллер 
// дисмиссится, соответственно не может продолжить работу.
// контроллеры, которые мы показыавем поверх должны наследоваться от этого контроллера.
@interface LightViewCompatibleController : UIViewController
@end
*/



