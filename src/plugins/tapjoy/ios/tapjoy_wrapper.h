#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void ml_tapjoy_init(value appid, value skey);
void ml_tapjoy_set_user_id(value userid);
CAMLprim value ml_tapjoy_get_user_id();
void ml_tapjoy_action_complete(value action);
void ml_tapjoy_show_offers();
void ml_tapjoy_show_offers_with_currency(value currency, value show_selector);
