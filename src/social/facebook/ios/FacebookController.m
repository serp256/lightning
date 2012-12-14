#import "FacebookController.h"

@implementation FacebookController

-(void)connect:(NSString*)appId {
    NSLog(@"ml_fbConnect");

    if (!fbSession) {
        [FBSession setDefaultAppID:appId];
        NSLog(@"pizda %d", (int)[FBSession openActiveSessionWithReadPermissions:nil
            allowLoginUI:YES
            completionHandler:^(FBSession* session, FBSessionState state, NSError* error) {
                NSLog(@"sessionStateChanged call block");
            }
        ]);
    }  
}

@end
/*#import <UIKit/UIKit.h>

#import "FacebookController.h"
#import <caml/mlvalues.h>
#import <caml/callback.h>
#import <caml/alloc.h>

@implementation FacebookController

@synthesize facebook = _facebook;


-(id)initWithAppId:(NSString *)appid {
  self = [super init];
  if (self) {
    self.facebook = [[Facebook alloc] initWithAppId:appid  andDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURLNofitication:) name: @"applicationHandleOpenURL" object: nil];
  }
  return self;
}

- (void)handleOpenURLNofitication:(NSNotification *)notification {
    [self.facebook handleOpenURL:[[notification userInfo] valueForKey: @"url"]]; 
}


- (void)fbDidLogin {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
  [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
  [defaults synchronize];

  value *mlf = (value*)caml_named_value("facebook_logged_in");
  if (mlf == NULL) {                                                                                                                   
    return;                                                                                                                          
  }                                               
  caml_callback(*mlf, Val_int(0));  
}


- (void)fbDidLogout {
  value *mlf = (value*)caml_named_value("facebook_logged_out");
  if (mlf == NULL) {                                                                                                                   
    return;                                                                                                                          
  }                                               
  caml_callback(*mlf, Val_int(0));      
}


- (void)fbDidNotLogin:(BOOL)cancelled {
  value *mlf = (value*)caml_named_value("facebook_login_cancelled");
  if (mlf == NULL) {                                                                                                                   
    return;                                                                                                                          
  }                                               
  caml_callback(*mlf, Val_int(0));  
}


- (void)fbSessionInvalidated {
  value *mlf = (value*)caml_named_value("facebook_session_invalidated");
  if (mlf == NULL) {                                                                                                                   
    return;                                                                                                                          
  }                                               
  caml_callback(*mlf, Val_int(0));  
}
 


 @end

*/