#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Instagram : NSObject <UIDocumentInteractionControllerDelegate>

+ (BOOL) postImage:(NSString*)fname;
+ (BOOL) postImage:(NSString*)fname withCaption:(NSString*)caption;

@end