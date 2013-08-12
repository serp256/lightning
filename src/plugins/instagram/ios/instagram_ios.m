#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <DocInteraction.h>

value ml_instagram_post(value v_fname, value v_text) {
	CAMLparam2(v_fname, v_text);

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]]) {
		static int init = 0;
		if (!init) {
			[DocInteraction setUTI:@"com.instagram.exclusivegram" andCaptionKey:@"InstagramCaption"];
			init = 1;
		}

		CAMLreturn([DocInteraction postImage:[NSString stringWithUTF8String:String_val(v_fname)] withCaption:[NSString stringWithUTF8String:String_val(v_text)]] ? Val_true : Val_false);
	}

	CAMLreturn(Val_false);
}