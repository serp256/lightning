#include "Instagram.h"
#import "LightViewController.h"

@interface Instagram ()

+ (Instagram *)sharedInstance;

@end

@implementation Instagram

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller {
    [controller release];
}    

+ (Instagram *)sharedInstance
{
    static Instagram* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Instagram alloc] init];
    });
    return sharedInstance;
}

+ (BOOL) postImage:(NSString*)fname {
    return [[Instagram sharedInstance] postImage:fname withCaption:nil];
}
+ (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption {
    return [[Instagram sharedInstance] postImage:fname withCaption:caption];
}

- (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption {
    NSURL* igFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fname ofType:nil]];

    UIDocumentInteractionController* documentController = [UIDocumentInteractionController interactionControllerWithURL:igFileURL];
    documentController.UTI = @"com.instagram.exclusivegram";
    documentController.delegate = self;
    [documentController retain];

    if (caption) {
        documentController.annotation = [NSDictionary dictionaryWithObject:caption forKey:@"InstagramCaption"];
    }

    return [documentController presentOpenInMenuFromRect:CGRectZero inView:[LightViewController sharedInstance].view animated:YES];
}

@end