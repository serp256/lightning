
#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"


void process_touches(UIView *view, NSSet* touches, UIEvent *event,  mlstage *mlstage) {
	value mltouch,mltouches,lst_el;
  Begin_roots2(mltouch,mltouches);
  CGSize viewSize = view.bounds.size;
  float xConversion = mlstage->width / viewSize.width;
  float yConversion = mlstage->height / viewSize.height;
  //double now = CACurrentMediaTime();
  mltouches = Val_int(0);
  for (UITouch *uiTouch in touches) // [event touchesForView:view])
  {
    CGPoint location = [uiTouch locationInView:view];
    CGPoint previousLocation = [uiTouch previousLocationInView:view];
    value mltouch = caml_alloc_tuple(8);
		Store_field(mltouch,0,caml_copy_int32((int)uiTouch));
		Store_field(mltouch,1,caml_copy_double(0.));
		Store_field(mltouch,2,caml_copy_double(location.x * xConversion));
		Store_field(mltouch,3,caml_copy_double(location.y * yConversion));
		Store_field(mltouch,4,1);// None
		Store_field(mltouch,5,1); // None
		Store_field(mltouch,6,Val_int(uiTouch.tapCount));
		Store_field(mltouch,7,Val_int(uiTouch.phase));
		//mltouch_create(now,, location.y * yConversion, previousLocation.x * xConversion, previousLocation.y * yConversion, uiTouch.tapCount, (SPTouchPhase) uiTouch.phase);            
    // добавить в список 
    lst_el = caml_alloc_small(2,0);
    Field(lst_el,0) = mltouch;
    Field(lst_el,1) = mltouches;
    mltouches = lst_el;
  }
	End_roots();
  mlstage_processTouches(mlstage,mltouches);
}

