#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void ml_vk_init(value appid);
void ml_vk_authorize(value permissions);
void ml_vk_display_captcha(value sid, value url);