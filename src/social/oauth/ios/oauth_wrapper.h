#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void ml_authorization_grant(value url);