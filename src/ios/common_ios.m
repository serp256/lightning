#import <Foundation/Foundation.h>

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/callback.h>
#import <caml/alloc.h>
#import <caml/fail.h>



CAMLprim value ml_bundle_path_for_resource(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal1(res);
	//fprintf(stderr,"ml_bundle_path: %s\n",String_val(mlpath));
	NSString *path = [NSString stringWithCString:String_val(mlpath) encoding:NSASCIIStringEncoding];
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
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
