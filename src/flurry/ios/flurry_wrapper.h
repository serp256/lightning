#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void ml_flurry_start_session(value ml_appkey);
void ml_flurry_log_event(value ml_evname, value ml_evtimed, value ml_evparams_opt);
void ml_flurry_end_timed_event(value ml_evname, value ml_evparams_opt);
void ml_flurry_set_user_id (value ml_uid);
void ml_flurry_set_user_age(value ml_age);
void ml_set_user_gender(value ml_gender);

