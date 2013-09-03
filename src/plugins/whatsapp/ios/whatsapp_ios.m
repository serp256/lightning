#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <DocInteraction.h>

value ml_whatsapp_installed(value p) {
	return Val_bool([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]);
}

value ml_whatsapp_text(value v_text) {
	CAMLparam1(v_text);

	NSString* text = [[NSString stringWithUTF8String:String_val(v_text)] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"whatsapp://send?text=%@", text]];

	if (![[UIApplication sharedApplication] canOpenURL:url]) {
		CAMLreturn(Val_false);
	}

	CAMLreturn([[UIApplication sharedApplication] openURL:url] ? Val_true : Val_false);
}

value ml_whatsapp_picture(value v_pic) {
	CAMLparam1(v_pic);

	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]) {
		static int init = 0;
		if (!init) {
			[DocInteraction setUTI:@"net.whatsapp.image"];
			init = 1;
		}

		CAMLreturn([DocInteraction postImage:[NSString stringWithUTF8String:String_val(v_pic)]] ? Val_true : Val_false);
	}

	CAMLreturn(Val_false);
}
