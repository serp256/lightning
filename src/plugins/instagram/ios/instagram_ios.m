#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <Instagram.h>

value ml_instagram_post(value v_fname, value v_text) {
	CAMLparam2(v_fname, v_text);

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]]) {
		CAMLreturn([Instagram postImage:[NSString stringWithUTF8String:String_val(v_fname)] withCaption:[NSString stringWithUTF8String:String_val(v_text)]] ? Val_true : Val_false);
	}

	CAMLreturn(Val_false);
}