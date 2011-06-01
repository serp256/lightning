include ../Makefile.common


%.o: %.c
	$(OCAMLOPT) -verbose -g -ccopt '-fPIC' -ccopt '-DGL_GLEXT_PROTOTYPES' -ccopt '-o $@' -c $<



MOBS = 
MLSOURCES = 
MLDEPFLAGS =

release: lightning.cmxa syntax/pa_prop.cmo
debug: release

SYNTAX = syntax/pa_prop.cmo syntax/pa_debug.cmo
$(SYNTAX): MLFLAGS = -package camlp4,camlp4.lib,camlp4.quotations.r,camlp4.extend -syntax camlp4r 
$(SYNTAX): MLPPOPT :=
$(SYNTAX): OCAMLC = ocamlfind ocamlc

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
	MLSOURCES += sdl/sdl.ml sdl/sdl_image.ml sdl/sdl_run.ml
	MLFLAGS += -I sdl
	MLDEPFLAGS += -I sdl sdl/*.ml sdl/*.mli
	MLPPOPT += -DSDL
	ifeq ($(OS),macos)
		LIBFLAGS = -cclib '-framework\ Cocoa' -cclib '-lSDL' -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-framework\ OpenGL'
	else
		LIBFLAGS = -cclib '-lSDL' -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-lGL'
	endif
endif


MOBS += $(gl)/gl_stub.o 

MLSOURCES += $(gl)/gl.ml Debug.ml MList.ml ProfTimer.ml PriorityQueue.ml WeakHashtbl.ml WeakMemo.ml LightCommon.ml Event.ml EventDispatcher.ml Point.ml Rectangle.ml Matrix.ml RenderSupport.ml \
					DisplayObject.ml Sprite.ml Quad.ml GLTexture.ml Texture.ml TextureAtlas.ml Image.ml CompiledSprite.ml Touch.ml BitmapFont.ml TextField.ml FPS.ml Timers.ml Timer.ml Stage.ml Button.ml MovieClip.ml Tween.ml Lightning.ml

MLFLAGS += -package extlib,xmlm -I $(gl)

#XMLMFILES = TextureAtlas.ml BitmapFont.ml LightCommon.ml MovieClip.ml
#$(XMLMFILES:.ml=.cmo) $(XMLMFILES:.ml=.cmx) $(XMLMFILES:.ml=.cmi): MLFLAGS += -package xmlm

MLOBS = $(MLSOURCES:.ml=.cmx)

$(MLOBS) MLDepend.$(PLATFORM): syntax/pa_debug.cmo 
#$(MLOBS): MLPPOPT += syntax/pa_debug.cmo 
$(MLOBS) MLDepend.$(PLATFORM): MLPPOPT += syntax/pa_debug.cmo 
-include debug.conf
	
lightning.cmxa: MLDepend.$(PLATFORM) $(MOBS) $(MLOBS)
	$(OCAMLMKLIB) -verbose -o lightning $(MOBS) $(MLOBS) $(LIBFLAGS) 

#$(OCAMLFIND) ocamldep -package camlp4,camlp4.macro -syntax camlp4r $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) -I $(gl) $(gl)/*.ml $(gl)/*.mli $(MLDEPFLAGS) *.ml *.mli  > MLDepend.$(PLATFORM)
MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep $(MLFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLSOURCES) *.mli > MLDepend.$(PLATFORM)


doc:
	mkdir -p docs
	$(OCAMLFIND) ocamldoc -short-functors -html -d docs $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLFLAGS) \
		MList.ml PriorityQueue.mli WeakHashtbl.mli WeakMemo.mli LightCommon.ml Event.ml EventDispatcher.ml Point.ml Rectangle.ml Matrix.ml DisplayObjectT.ml DisplayObject.mli Sprite.mli Quad.mli \
		Texture.mli TextureAtlas.mli Image.mli CompiledSprite.mli Touch.ml BitmapFont.mli TextField.mli Stage.mli Button.mli MovieClip.mli Tween.mli Lightning.ml


.DEFAULT_GOAL := release

.PHONY : clean
clean: 
	rm -f *.o *.cm[iox] *.a *.cmxa *.so ios/*.o sdl/*.cmx sdl/*.o sdl/*.cmi $(gl)/*.o $(gl)/*.cmx $(gl)/*.cmi *.html *.css MLDepend.* syntax/*.cmo syntax/*.cmi

-include MLDepend.$(PLATFORM)
-include debug.conf
