#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DocInteraction : NSObject <UIDocumentInteractionControllerDelegate>

+ (void) setUTI:(NSString*)uti;
+ (void) setUTI:(NSString*)uti andCaptionKey:(NSString*)key;
+ (BOOL) postImage:(NSString*)fname;
+ (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption;

@end