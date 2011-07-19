
#include <SDL/SDL_image.h>


#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/callback.h>


extern void raise_faliure(void);

void ml_IMG_Init(value flag) {
	CAMLparam1(flag);
	int r = IMG_Init(Int_val(flag));
	if (r < 0) raise_failure();
	CAMLreturn0;
}


CAMLprim value ml_IMG_Load(value path) {
	CAMLparam1(path);
	SDL_Surface* s = IMG_Load(String_val(path));
	if (s == NULL) raise_failure();
	value r = caml_alloc_small(1,Abstract_tag);
	Field(r,0) = (value)s;
	CAMLreturn(r);
}
