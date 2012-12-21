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

@implementation LightAppDelegate

@synthesize window=_window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].applicationFrame];
	lightViewController = [LightViewController sharedInstance];
	lightViewController.orientationDelegate = self;
	//[self.window addSubview:lightViewController.view];    
	self.window.rootViewController = lightViewController;
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


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  
	NSLog(@"didRegisterForRemote");
  if (Is_long(lightViewController->remote_notification_request_success_cb)) {
    NSLog(@"You requested for remote notifications, but didn't provide a success callback");
    return;
  }

  caml_acquire_runtime_system();
  value token;
  Begin_roots1(token);

  token = caml_alloc_string([deviceToken length]);
  memmove(String_val(token), (const char *)[deviceToken bytes], [deviceToken length]);  
  caml_callback(lightViewController->remote_notification_request_success_cb,token);
  
  [self clearRemoteNotificationsRequestCallbacks];
  
  End_roots();
  caml_release_runtime_system();
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

  caml_acquire_runtime_system();

  if (Is_block(lightViewController->remote_notification_request_error_cb)) {
    NSString *errdesc = [error localizedDescription];                                                                                                                                                     
    caml_callback(lightViewController->remote_notification_request_error_cb, caml_copy_string([errdesc cStringUsingEncoding:NSUTF8StringEncoding]));
  }

  [self clearRemoteNotificationsRequestCallbacks];
  
  caml_release_runtime_system();  
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

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation for lLightAppDelegate");
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate {
	NSLog(@"shouldAutorotate for lLightAppDelegate");
	return YES;
}

-(NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
	return UIInterfaceOrientationMaskAllButUpsideDown;
}     

- (NSUInteger)supportedInterfaceOrientations {
	NSLog(@"supportedInterfaceOrientations for lLightAppDelegate");
  return UIInterfaceOrientationMaskPortrait;;
//	return UIInterfaceOrientationMaskLandscape;
}

- (void)dealloc {
	[lightViewController release];
	[_window release];
	[super dealloc];
}

@end

