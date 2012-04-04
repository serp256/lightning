#import "FacebookDialogDelegate.h"

#import <caml/mlvalues.h>                                                                                                                                                                  
#import <caml/callback.h>                                                                                                                                                                  
#import <caml/alloc.h>

@implementation FacebookDialogDelegate

/*
 *
 */
- (id)initWithDialogID: (int)dialogID {
    self = [super init];
    if (self) {
        _dialogID = dialogID;
    }
    return self;
}


/*
 *
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    [self release];
}


/*
 *
 */
- (void)dialogDidNotComplete:(FBDialog *)dialog {
    value *mlf = (value*)caml_named_value("facebook_dialog_did_cancel");
    if (mlf == NULL) {
        return;       
    }
    caml_callback(*mlf, Val_int(_dialogID));    
    [self release];
}


/*
 *
 */
- (void)dialogCompleteWithUrl:(NSURL *)url {
    value *mlf;
    if (url == nil || [url query] == nil || [[url query] rangeOfString: @"request="].location == NSNotFound) {
        mlf = (value*)caml_named_value("facebook_dialog_did_cancel");
    } else {
        mlf = (value*)caml_named_value("facebook_dialog_did_complete");
    }
    
    if (mlf == NULL) {
        return;       
    }
    caml_callback(*mlf, Val_int(_dialogID));
}



/*
 *
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    NSString * errorStr = [error localizedDescription];
    value *mlf = (value*)caml_named_value("facebook_dialog_did_fail_with_error");
    if (mlf == NULL) {
        return;       
    }
    caml_callback2(*mlf, Val_int(_dialogID), caml_copy_string([errorStr UTF8String]));
}



/*
 *
 */
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url {
    return NO;
    
    /*
    value *mlf = (value*)caml_named_value("facebook_dialog_should_open_url");
    if (mlf == NULL) {
        return NO;       
    }
    value ret = caml_callback2(*mlf, Val_int(_dialogID), caml_copy_string([[url absoluteString] UTF8String]));
    return Int_val(ret);
    */
}

@end

