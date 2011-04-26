include ../Makefile.include

%.o: %.c
	$(OCAMLOPT) -g -ccopt '-o $@' -c $<

MOBS = 
MLOBS = 
MLDEPFLAGS =

ifeq ($(PLATFORM),ios)
	gl = gl/es
	CFLAGS += -I .
	MOBS += mlwrapper.o ios/mlwrapper_ios.o ios/LightView.o ios/texture.o
	MLPPOPT += -DGLES -DIOS
	LIBFLAGS = -cclib '-framework\ Foundation' \
						 -cclib '-framework\ UIKit' \
						 -cclib '-framework\ QuartzCore' \
						 -cclib '-framework\ CoreGraphics' \
						 -cclib '-framework\ OpenGLES'
else
	gl = gl/2.1
	MOBS += sdl/sdl_stub.o sdl/sdl_image_stub.o
	MLOBS += sdl/sdl.cmx sdl/sdl_image.cmx sdl/sdl_run.cmx
	MLFLAGS += -I sdl
	MLDEPFLAGS += -I sdl sdl/*.ml sdl/*.mli
	MLPPOPT += -DSDL
	LIBFLAGS = -cclib '-framework\ Cocoa' -cclib '-lSDL' -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-framework\ OpenGL'
endif


MOBS += $(gl)/gl_stub.o 
MLOBS += $(gl)/gl.cmx \
				MList.cmx ObjMemo.cmx LightCommon.cmx Event.cmx EventDispatcher.cmx Point.cmx Rectangle.cmx Matrix.cmx RenderSupport.cmx \
				DisplayObject.cmx Sprite.cmx Quad.cmx GLTexture.cmx Texture.cmx TextureAtlas.cmx Image.cmx Touch.cmx CompiledSprite.cmx BitmapFont.cmx TextField.cmx Button.cmx Stage.cmx Lightning.cmx


MLFLAGS += -package extlib -I $(gl)


XMLMFILES = TextureAtlas.ml BitmapFont.ml LightCommon.ml
$(XMLMFILES:.ml=.cmo) $(XMLMFILES:.ml=.cmx) $(XMLMFILES:.ml=.cmi): MLFLAGS += -package xmlm
	
lightning.cmxa: MLDepend.$(PLATFORM) $(MOBS) $(MLOBS)
	$(OCAMLLIB) -verbose -o lightning $(MOBS) $(MLOBS) $(LIBFLAGS) 

MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep -package camlp4,camlp4.macro -syntax camlp4r $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) -I $(gl) $(gl)/*.ml $(gl)/*.mli $(MLDEPFLAGS) *.ml *.mli  > MLDepend.$(PLATFORM)

-include MLDepend.$(PLATFORM)

.DEFAULT_GOAL := lightning.cmxa 

.PHONY : clean
clean: 
	rm -f *.o *.cm[iox] *.a *.cmxa *.so ios/*.o sdl/*.{cmx,o,cmi} $(gl)/*.{o,cmx,cmi}

