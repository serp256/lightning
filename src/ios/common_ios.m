#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/callback.h>
#import <caml/alloc.h>
#import <caml/fail.h>

#import "mlwrapper_ios.h"
#import "mobile_res.h"

/*
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
*/

int getResourceFd(const char *path, resource *res) {
	PRINT_DEBUG("getResourceFd call %s", path);

	offset_size_pair_t* os_pair;

	if (!get_offset_size_pair(path, &os_pair)) {
		PRINT_DEBUG("found");

		int fd;

		if (os_pair->location == 0) {
			char* bpath = bundle_path("assets");
			if (bpath == nil) {
				PRINT_DEBUG("bundlePath == nil for '%s'", path);
				return 0;
			}

			fd = open(bpath, O_RDONLY);
		} else {
			PRINT_DEBUG("invalid location for path %s", path);
			return 0;
		}

		lseek(fd, os_pair->offset, SEEK_SET);

		res->fd = fd;
		res->length = os_pair->size;

		PRINT_DEBUG("fd for %s opened", path);

		return 1;
	}

	PRINT_DEBUG("not found");

	return 0;
}

/*CAMLprim value ml_bundle_path_for_resource(value mlpath,value mlsuffix) {
	CAMLparam1(mlpath);
	CAMLlocal1(res);

	// третья версия прошивки не понимает, когда путь содержит подпапки. сцуконах.	
	NSString *path = [NSString stringWithCString:String_val(mlpath) encoding:NSASCIIStringEncoding];
	NSString *bundlePath = nil;
	NSArray * components = [path pathComponents];
	NSString * ext = [path pathExtension];
    
	if (Is_block(mlsuffix)) {
		NSString *suffix = [NSString stringWithCString:String_val(Field(mlsuffix,0)) encoding:NSASCIIStringEncoding];
		if ([components count] > 1) {
			NSString * lastComponentWOext = [[components lastObject] stringByDeletingPathExtension];
			bundlePath = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%@%@.%@", lastComponentWOext, suffix, ext] ofType:nil inDirectory: [path stringByDeletingLastPathComponent]]; 
		} else {
			NSString * pathWOext = [path stringByDeletingPathExtension];
			bundlePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@%@.%@", pathWOext,suffix,ext] ofType:nil];        
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
}*/




CAMLprim value ml_storage_path(value p) {
	CAMLparam0();
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	value result = caml_copy_string([[paths objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding]);
	CAMLreturn(result);
}




