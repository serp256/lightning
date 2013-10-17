#import "LightAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>
#import <Foundation/Foundation.h>
#import "LightViewController.h"

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>
#import "mlwrapper.h"


void set_referrer(char *type,NSString *nid) {
	CAMLparam0();
	CAMLlocal2(mltype,mlnid);
	mltype = caml_copy_string(type);
	mlnid = caml_copy_string([nid cStringUsingEncoding:NSASCIIStringEncoding]);
	set_referrer_ml(mltype,mlnid);
	CAMLreturn0;
}

@implementation LightAppDelegate

@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	//CGRect frame = [UIScreen mainScreen].applicationFrame;
	//NSLog(@"window size: %f:%f:%f:%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	lightViewController = [LightViewController sharedInstance];
	lightViewController.orientationDelegate = self;
	//[self.window addSubview:lightViewController.view];    
	self.window.rootViewController = lightViewController;
	// For local notifications
	UILocalNotification *ln = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	if (ln) {
		NSString *nid = [ln.userInfo objectForKey:@"id"];
		NSLog(@"didReceiveLocalNotification: %@",nid);
		if (nid) set_referrer("local",nid);
	} else {
		// For remote notifications
		NSDictionary *rn = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
		if (rn) {
			NSString *nid = [rn objectForKey:@"id"];
			NSLog(@"didReceiveRemoteNotification: %@",nid);
			if (nid) set_referrer("remote",nid);
		};
	};
	[self.window makeKeyAndVisible];
	return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application        {
	NSLog(@"resign active");
	[lightViewController resignActive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application         {
	// NSLog(@"become active %@", [FBSession defaultAppID]);


  // [FBSession defaultAppID] ? [[FBSession activeSession] handleDidBecomeActive] : NO;
  [[NSNotificationCenter defaultCenter] postNotificationName:APP_BECOME_ACTIVE_NOTIFICATION object:self];
	[lightViewController becomeActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application      {
	NSLog(@"did enter background");
	[lightViewController background];
}

- (void)applicationWillEnterForeground:(UIApplication *)application     {
	NSLog(@"did enter foreground");
	[lightViewController foreground];
}

- (void)applicationWillTerminate:(UIApplication *)application           {
	NSLog(@"wil terminate");
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	NSLog(@"AppDelegate memory warning");
}


/*
-(void)clearRemoteNotificationsRequestCallbacks {

  if (Is_block(lightViewController->remote_notification_request_success_cb)) {
    caml_remove_global_root(&(lightViewController->remote_notification_request_success_cb));
    lightViewController->remote_notification_request_success_cb = Val_int(1);
  }
  
    if (Is_block(lightViewController->remote_notification_request_error_cb)) {
    caml_remove_global_root(&(lightViewController->remote_notification_request_error_cb));
    lightViewController->remote_notification_request_error_cb = Val_int(1);
  }
  
}
*/

/*
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	// This is remote notification
}
*/


-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	// This is local notification
	// Get the user data
	NSString *nid = [notification.userInfo objectForKey:@"id"];
	NSLog(@"didReceiveLocalNotification: %@",nid);
	if (nid) set_referrer("local",nid);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	if (lightViewController && lightViewController.rnDelegate) {
		[lightViewController.rnDelegate didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
		lightViewController.rnDelegate = nil;
	}
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	if (lightViewController && lightViewController.rnDelegate) {
		[lightViewController.rnDelegate didFailToRegisterForRemoteNotificationsWithError:error];
		lightViewController.rnDelegate = nil;
	}
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
/*	 	NSString *urlString = [url absoluteString];
	  const char *str = [urlString UTF8String];
		NSLog(@"UIApplication handleOpenURL %s", str);
    [[NSNotificationCenter defaultCenter] postNotificationName: @"applicationHandleOpenURL" object: self userInfo: [NSDictionary dictionaryWithObject: url forKey:@"url"]];
    return YES;*/
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_HANDLE_OPEN_URL_NOTIFICATION object:self userInfo:[NSDictionary dictionaryWithObject:url forKey:APP_HANDLE_OPEN_URL_NOTIFICATION_DATA]];

    return YES;
    // return [FBSession defaultAppID] ? [[FBSession activeSession] handleOpenURL:url] : NO;
}

    
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
/*	 	NSString *urlString = [url absoluteString];
	  const char *str = [urlString UTF8String];
		NSLog(@"UIApplication openURL %s", str);
    [[NSNotificationCenter defaultCenter] postNotificationName: @"applicationHandleOpenURL" object: self userInfo: [NSDictionary dictionaryWithObject: url forKey:@"url"]];
    return YES;*/
    [[NSNotificationCenter defaultCenter] postNotificationName:APP_HANDLE_OPEN_URL_NOTIFICATION object:self userInfo:[NSDictionary dictionaryWithObject:url forKey:APP_HANDLE_OPEN_URL_NOTIFICATION_DATA]];

    return YES;
    // return [FBSession defaultAppID] ? [[FBSession activeSession] handleOpenURL:url] : NO;
}

-(BOOL)shouldAutorotate {
	NSLog(@"delegate shouldAutorotate");
	return YES;
}

/*
-(BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation {
	  NSLog(@"delegate shouldAutotaitate interfaceOrientation");
		return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}
*/

/*
-(BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation {
	  NSLog(@"delegate shouldAutotaitate interfaceOrientation");
		return ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown));
}
*/

/*
-(NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
	NSLog(@"delegate application supportedInterfaceOrienationsForWindow");
	return UIInterfaceOrientationMaskPortrait;
	//return UIInterfaceOrientationMaskAllButUpsideDown;
}     
*/

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"shouldAutorotateToInterfaceOrientation from nano delegate");
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationMaskPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations {
	NSLog(@"delegate supportedInterfaceOrientations");
  return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskAllButUpsideDown);
}

- (void)dealloc {
	[lightViewController release];
	[_window release];
	[super dealloc];
}

@end

