#import "FacebookRequestDelegate.h"

#import <caml/mlvalues.h>                                                                                                                                                                 
#import <caml/callback.h>                                                                                                                                                                 
#import <caml/alloc.h>

@implementation FacebookRequestDelegate

/*                                                                                                                                                                                        
 *                                                                                                                                                                                        
 */                                                                                                                                                                                       
- (id)initWithRequestID: (int)requestID {                                                                                                                                                   
    self = [super init];                                                                                                                                                                  
    if (self) {                                                                                                                                                                           
        _requestID = requestID;
    }                                                                                                                                                                                     
    return self;                                                                                                                                                                          
}


/*
 *
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    [self release];
}

/*                                                                                                                                                                                        
 *                                                                                                                                                                                        
 */                                                                                                                                                                                       
-(void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data {                                                                                                                   
    NSString * json = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    value *mlf = (value*)caml_named_value("facebook_request_did_load");                                                                                                                     
    if (mlf == NULL) {                                                                                                                                                                      
        return;                                                                                                                                                                               
    }                                                                                                                                                                                       
    
    caml_callback2(*mlf, Val_int(_requestID), caml_copy_string([json UTF8String]));                                                                                    
    [json release];                                                                                                                                                                         
}



/*                                                                                                                                                                                        
 *                                                                                                                                                                                        
 */                                                                                                                                                                                       
-(void)request:(FBRequest *)request didFailWithError:(NSError *)error {                                                                                                                   
    NSString * errorStr = [error localizedDescription];                                                                                                                                     
    value *mlf = (value*)caml_named_value("facebook_request_did_fail");                                                                                                                     
    if (mlf == NULL) {                                                                                                                                                                      
        return;                                                                                                                                                                               
    }                                                                                                                                                                                       
    
    caml_callback2(*mlf, Val_int(_requestID), caml_copy_string([errorStr UTF8String]));                                                                                
    [self release];
}

@end