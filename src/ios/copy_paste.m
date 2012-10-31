#import <UIKit/UIKit.h>
#import <CoreMotion/CMMotionManager.h>
#import <QuartzCore/CABase.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>
#import "LightViewController.h"

value ml_paste() {
	CAMLparam0();
	CAMLlocal1(r);
	[[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard]; 
	NSString * a = pasteboard.string;
	if (a==nil) {
  	r = caml_copy_string ("");
	} else {
  	r = caml_copy_string ( [a UTF8String] );
	}
	CAMLreturn(r);
}

void ml_copy (value st)
{
	CAMLparam1(st);
	NSString *s = [NSString stringWithCString:String_val(st) encoding:NSUTF8StringEncoding];
	[[UIPasteboard generalPasteboard] setString:s];
	CAMLreturn0;
}

void ml_keyboard (value visible, value size, value initString, value returnCallback, value updateCallback)
{
	CAMLparam4(size, initString, updateCallback, returnCallback);
 	NSLog (@"initString %@", [NSString stringWithCString:String_val(initString) encoding:NSASCIIStringEncoding] ); 
	[[LightViewController sharedInstance] showKeyboard:visible size:size updateCallback:updateCallback returnCallback:returnCallback initString:initString];
	CAMLreturn0;
}

void ml_hidekeyboard ()
{
	CAMLparam0();
	[[LightViewController sharedInstance] hideKeyboard];
	CAMLreturn0;
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
