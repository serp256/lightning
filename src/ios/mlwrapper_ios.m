
#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import "mlwrapper_ios.h"


void process_touches(UIView *view, NSSet* touches, UIEvent *event,  mlstage *mlstage) {
	value mltouch,mltouches,globalX,globalY,lst_el;
  Begin_roots4(mltouch,globalX,globalY,mltouches);
  CGSize viewSize = view.bounds.size;
  float xConversion = mlstage->width / viewSize.width;
  float yConversion = mlstage->height / viewSize.height;
  mltouches = Val_int(0);
  for (UITouch *uiTouch in touches) // [event touchesForView:view])
  {
    CGPoint location = [uiTouch locationInView:view];
    CGPoint previousLocation = [uiTouch previousLocationInView:view];
		globalX = caml_copy_double(location.x * xConversion);
		globalY = caml_copy_double(location.y * yConversion);
    value mltouch = caml_alloc_tuple(8);
		Store_field(mltouch,0,caml_copy_int32((int)uiTouch));
		Store_field(mltouch,1,caml_copy_double(0.));
		Store_field(mltouch,2,globalX);
		Store_field(mltouch,3,globalY);
		Store_field(mltouch,4,globalX);
		Store_field(mltouch,5,globalY);
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

