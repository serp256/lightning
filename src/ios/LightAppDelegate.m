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
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	NSLog(@"window size: %f:%f:%f:%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
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

#ifdef __IPHONE_8_0

- (BOOL)checkNotificationType:(UIUserNotificationType)type
{
  UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];

  return (currentSettings.types & type);
}

#endif

- (void)setApplicationBadgeNumber:(NSInteger)badgeNumber
{
  UIApplication *application = [UIApplication sharedApplication];

#ifdef __IPHONE_8_0
  if(SYSTEM_VERSION_LESS_THAN(@"8.0"))
  {
    application.applicationIconBadgeNumber = badgeNumber;
  }
  else
  {
    if ([self checkNotificationType:UIUserNotificationTypeBadge])
    {
      application.applicationIconBadgeNumber = badgeNumber;
    }
    else
      NSLog(@"access denied for UIUserNotificationTypeBadge");
  }

#else
  application.applicationIconBadgeNumber = badgeNumber;
#endif
}


- (void)applicationWillResignActive:(UIApplication *)application        {
	NSLog(@"resign active");
	[lightViewController resignActive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application         {
	NSLog(@"become active");

  	/*application.applicationIconBadgeNumber = 0;*/
		[self setApplicationBadgeNumber:0];
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
	[url retain];
	NSDictionary* data = [NSDictionary dictionaryWithObject:url forKey:APP_URL_DATA];

    [[NSNotificationCenter defaultCenter] postNotificationName:APP_OPENURL object:self userInfo:data];
    return YES;
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	[url retain];
	[sourceApplication retain];
	NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys: url, APP_URL_DATA, sourceApplication, APP_SOURCEAPP_DATA, nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:APP_OPENURL_SOURCEAPP object:self userInfo:data];
    return YES;
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

-(NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
	NSLog(@"delegate application supportedInterfaceOrienationsForWindow");
	//return UIInterfaceOrientationMaskPortrait;
	return UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"shouldAutorotateToInterfaceOrientation from light app delegate");
	return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationMaskPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations {
	NSLog(@"supportedInterfaceOrientations from light app delegate");
  return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
	[lightViewController release];
	[_window release];
	[super dealloc];
}

@end
