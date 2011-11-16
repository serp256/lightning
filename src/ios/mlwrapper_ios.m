
#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import <caml/threads.h>
#import "mlwrapper_ios.h"
#import "LightViewController.h"


void process_touches(UIView *view, NSSet* touches, UIEvent *event,  mlstage *mlstage) {
	caml_acquire_runtime_system();
	value mltouch = 1,mltouches = 1,globalX = 1,globalY = 1,time = 1, lst_el = 1;
  Begin_roots5(mltouch,time,globalX,globalY,mltouches);
  CGSize viewSize = view.bounds.size;
  float xConversion = mlstage->width / viewSize.width;
  float yConversion = mlstage->height / viewSize.height;
  mltouches = Val_int(0);
	time = caml_copy_double(0.);
  for (UITouch *uiTouch in touches) // [event touchesForView:view])
  {
    CGPoint location = [uiTouch locationInView:view];
		globalX = caml_copy_double(location.x * xConversion);
		globalY = caml_copy_double(location.y * yConversion);
    value mltouch = caml_alloc_tuple(8);
		Store_field(mltouch,0,caml_copy_int32((int)uiTouch));
		Store_field(mltouch,1,time);
		Store_field(mltouch,2,globalX);
		Store_field(mltouch,3,globalY);
		Store_field(mltouch,4,globalX);
		Store_field(mltouch,5,globalY);
		Store_field(mltouch,6,Val_int(uiTouch.tapCount));
		Store_field(mltouch,7,Val_int(uiTouch.phase));
    lst_el = caml_alloc_small(2,0);
    Field(lst_el,0) = mltouch;
    Field(lst_el,1) = mltouches;
    mltouches = lst_el;
  }
  mlstage_processTouches(mlstage,mltouches);
	End_roots();
	caml_release_runtime_system();
}


void ml_showActivityIndicator(value mlpos) {
	CAMLparam1(mlpos);
	LightViewController *c = [LightViewController sharedInstance];
	CGPoint pos = CGPointMake(Double_field(mlpos,0),Double_field(mlpos,1));
	[c showActivityIndicator:pos];
	CAMLreturn0;
}

void ml_hideActivityIndicator(value p) {
	[[LightViewController sharedInstance] hideActivityIndicator];
}


value ml_deviceIdentifier(value p) {
	CAMLparam0();
	NSString *ident = [[UIDevice currentDevice] uniqueIdentifier];
	CAMLreturn(caml_copy_string([ident cStringUsingEncoding:NSASCIIStringEncoding]));
}


void ml_openURL(value mlurl) {
	CAMLparam1(mlurl);
	NSString *url = [NSString stringWithCString:String_val(mlurl) encoding:NSUTF8StringEncoding];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	CAMLreturn0;
}
