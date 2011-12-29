#import <caml/memory.h>                                                                                                                                                       
#import <caml/mlvalues.h>                                                                                                                                                     
#import <caml/alloc.h>                                                                                                                                                        
#import <caml/threads.h> 

void ml_facebook_init(value appid);
value ml_facebook_check_auth_token();
void ml_facebook_authorize(value permissions);
void ml_facebook_request(value graph_path, value params, value request_id);
void ml_facebook_open_apprequest_dialog(value ml_message, value ml_recipients, value ml_filter, value ml_title, value ml_dialog_id);