
#import "FBConnect.h"

@interface FacebookDialogDelegate : NSObject <FBDialogDelegate> {
    int _dialogID;
}
- (id)initWithDialogID: (int)dialogID;
- (void)dialogDidComplete:(FBDialog *)dialog;
- (void)dialogCompleteWithUrl:(NSURL *)url;
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url;
- (void)dialogDidNotComplete:(FBDialog *)dialog;
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error;
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;
@end