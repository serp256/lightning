#import <UIKit/UIKit.h>
#import <CoreMotion/CMMotionManager.h>
#import <QuartzCore/CABase.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>

value ml_paste() {
	CAMLparam0();
	CAMLlocal1(r);
	[[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard]; 
	NSString * a = pasteboard.string;
  r = caml_copy_string ( [a UTF8String] );
	CAMLreturn(r);
}

void ml_copy (value st)
{
	CAMLparam1(st);
	NSString *s = [[NSString alloc] initWithCString:st];
	[[UIPasteboard generalPasteboard] setString:s];
	CAMLreturn0;
}

