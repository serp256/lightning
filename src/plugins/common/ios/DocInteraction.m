#include "DocInteraction.h"
#import "LightViewController.h"

static NSString* UTI = nil;
static NSString* captionKey = nil;

@interface DocInteraction ()

+ (DocInteraction*)sharedInstance;

@end

@implementation DocInteraction

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller {
    [controller release];
}    

+ (DocInteraction *)sharedInstance
{
    static DocInteraction* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DocInteraction alloc] init];
    });
    return sharedInstance;
}

+ (void)setUTI:(NSString*)uti {
    UTI = uti;
}

+ (void)setUTI:(NSString*)uti andCaptionKey:(NSString*)key {
    UTI = uti;
    captionKey = key;
}

+ (BOOL) postImage:(NSString*)fname {
    return [[DocInteraction sharedInstance] postImage:fname withCaption:nil];
}
+ (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption {
    return [[DocInteraction sharedInstance] postImage:fname withCaption:caption];
}

- (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption {
    // NSURL* igFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fname ofType:nil]];
    NSURL* igFileURL = [NSURL fileURLWithPath:fname];

    UIDocumentInteractionController* documentController = [UIDocumentInteractionController interactionControllerWithURL:igFileURL];
    documentController.UTI = UTI;
    documentController.delegate = self;
    [documentController retain];

    if (caption && captionKey) {
        documentController.annotation = [NSDictionary dictionaryWithObject:caption forKey:captionKey];
    }

    return [documentController presentOpenInMenuFromRect:CGRectZero inView:[LightViewController sharedInstance].view animated:YES];
}

@end