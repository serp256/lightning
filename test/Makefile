

sdl:
	$(MAKE) -f Makefile.sdl

clean: 
	$(MAKE) -f Makefile.sdl clean

ios:
	$(MAKE) -f Makefile.ios

iosclean:
	$(MAKE) -f Makefile.ios clean


android: 
	$(MAKE) -f Makefile.android


.PHONY: android ios sdl


KAZMATHOBJS = utility.o vec2.o vec4.o vec3.o mat3.o quaternion.o mat4.o neon_matrix_impl.o GL/mat4stack.o GL/matrix.o
KAZMATH = $(patsubst %,../src/kazmath/%,$(KAZMATHOBJS))

mat: mat.c
	gcc -o mat -I ../src mat.c $(KAZMATH)
