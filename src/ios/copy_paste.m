#import <UIKit/UIKit.h>
#import <CoreMotion/CMMotionManager.h>
#import <QuartzCore/CABase.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>
#import "LightViewController.h"

value ml_paste(value vcallback) {
	CAMLparam1(vcallback);
	CAMLlocal1(r);
	[[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	NSString * a = pasteboard.string;
	if (a==nil) {
  	r = caml_copy_string ("");
	} else {
  	r = caml_copy_string ( [a UTF8String] );
	}
	caml_callback(vcallback, r);
	CAMLreturn(Val_unit);
}

value ml_copy (value st)
{
	CAMLparam1(st);
	NSString *s = [NSString stringWithCString:String_val(st) encoding:NSUTF8StringEncoding];
	[[UIPasteboard generalPasteboard] setString:s];
	CAMLreturn(Val_unit);
}

value ml_keyboard (value filter, value visible, value size, value initString, value returnCallback, value updateCallback)
{
	CAMLparam4(size, initString, updateCallback, returnCallback);
 	NSLog (@"initString %@", [NSString stringWithCString:String_val(initString) encoding:NSASCIIStringEncoding] );
	[[LightViewController sharedInstance] showKeyboard:visible size:size updateCallback:updateCallback returnCallback:returnCallback initString:initString filter:filter];
	CAMLreturn(Val_unit);
}

value ml_keyboard_byte(value* argv, int argc) {
	return ml_keyboard(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}
value ml_hidekeyboard ()
{
	[[LightViewController sharedInstance] hideKeyboard];
	return Val_unit;
}

value ml_cleankeyboard ()
{
	[[LightViewController sharedInstance] cleanKeyboard];
	return Val_unit;
}

/*
value ml_keyboard_get ()
{
	CAMLparam0();
	CAMLlocal1(r);
	r= caml_copy_string ( [[[LightViewController sharedInstance] getKeyboardText] UTF8String] );
	CAMLreturn (r);
}
*/
