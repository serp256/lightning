#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/callback.h>
#import <caml/alloc.h>
#import <caml/fail.h>


float deviceScaleFactor() {
  UIScreen * s = [UIScreen mainScreen];
  if ([s respondsToSelector: @selector(scale)]) {
    return s.scale;
  }
  return 1.0;
}


CAMLprim value ml_device_scale_factor() {
  CAMLparam0();
  CAMLreturn(caml_copy_double(deviceScaleFactor()));
}


CAMLprim value ml_bundle_path_for_resource(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal1(res);

    // третья версия прошивки не понимает, когда путь содержит подпапки. сцуконах.	
	NSString *path = [NSString stringWithCString:String_val(mlpath) encoding:NSASCIIStringEncoding];
	NSString *bundlePath = nil;
    NSArray * components = [path pathComponents];
    NSString * ext = [path pathExtension];
    
    // сперва пробуем @2x
    if (deviceScaleFactor() != 1.0) {
      if ([components count] > 1) {
        NSString * lastComponentWOext = [[components lastObject] stringByDeletingPathExtension];
        bundlePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%@@2x.%@", lastComponentWOext, ext] ofType:nil inDirectory: [path stringByDeletingLastPathComponent]]; 
      } else {
        NSString * pathWOext = [path stringByDeletingPathExtension];
        bundlePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@@2x.%@", pathWOext, ext] ofType:nil];        
      }	                           
    }
    
    if (bundlePath == nil) {
      if ([components count] > 1) {
        bundlePath = [[NSBundle mainBundle] pathForResource: [components lastObject] ofType:nil inDirectory: [path stringByDeletingLastPathComponent]]; 
      } else {
        bundlePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
      }	                         
    }
    
	if (bundlePath == nil) {
		res = Val_int(0);
	} else {
		res = caml_alloc_tuple(1);
		Store_field(res,0,caml_copy_string([bundlePath cStringUsingEncoding:NSASCIIStringEncoding]));
	}
	CAMLreturn(res);
}




CAMLprim value ml_storage_path(value p) {
	CAMLparam0();
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	value result = caml_copy_string([[paths objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding]);
	CAMLreturn(result);
}




