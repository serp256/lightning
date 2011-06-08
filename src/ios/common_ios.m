#import <Foundation/Foundation.h>

#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/callback.h>
#import <caml/fail.h>

NSString *pathForResource(NSString *path, float contentScaleFactor) {
    NSString *fullPath = NULL;
    if ([path isAbsolutePath]) {
        fullPath = path; 
    } else {
        NSBundle *bundle = [NSBundle mainBundle];
        if (contentScaleFactor != 1.0f)
        {
            NSString *suffix = [NSString stringWithFormat:@"@%@x", [NSNumber numberWithFloat:contentScaleFactor]];
            NSString *fname = [[path stringByDeletingPathExtension] stringByAppendingFormat:@"%@.%@", suffix, [path pathExtension]];
            fullPath = [bundle pathForResource:fname ofType:nil];
        }
        if (!fullPath) fullPath = [bundle pathForResource:path ofType:nil];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
			const char *fname = [path cStringUsingEncoding:NSASCIIStringEncoding];
			caml_raise_with_string(*caml_named_value("File_not_exists"), fname);
    }
    return fullPath;
}



CAMLprim value ml_bundle_path_for_resource(value mlpath) {
	CAMLparam1(mlpath);
	CAMLlocal1(res);
	fprintf(stderr,"ml_bundle_path: %s\n",String_val(mlpath));
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
