#import "AppDelegate.h"

@implementation AppDelegate

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutorotateToInterfaceOrientation from nano delegate");
	return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

-(BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation {
	NSLog(@"shouldAutotaitate from nano delegate");
	return ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight));
}

-(NSUInteger)supportedInterfaceOrientations {
	NSLog(@"supportedInterfaceOrientations from nano delegate");
	return UIInterfaceOrientationMaskLandscape;
}

@end