#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void ml_authorization_grant(value url);
void ml_set_close_button_insets(value top, value left, value bottom, value right);
void ml_set_close_button_visible(value visible);
void ml_set_close_button_image_name(value name);