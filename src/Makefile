include ../Makefile.common



MLCFLAGS = 
%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(MLCOPTS),$(patsubst %,-ccopt %,$(MLCOPTS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<


GLPARAM = 
CFLAGS += -I .

MOBJS = texture_common.o
MLOBJSFLAGS = 
MLFLAGS +=  -package extlib -I containers -I utils
MLDEPFLAGS =

release: lightning.cmxa syntax/pa_prop.cmo
debug: release

SYNTAX = syntax/pa_prop.cmo syntax/pa_debug.cmo
$(SYNTAX): MLFLAGS = -package camlp4,camlp4.lib,camlp4.quotations.r,camlp4.extend -syntax camlp4r 
$(SYNTAX): MLPPOPT :=
#$(SYNTAX): OCAMLC = ocamlfind ocamlc


ifeq ($(PLATFORM),ios)
	gl = gl/es
	CFLAGS +=  -DDEBUG
	MLCOPTS += -DIOS
	MOBJS += mlwrapper.o ios/mlwrapper_ios.o ios/LightView.o ios/LightViewController.o ios/common_ios.o ios/texture_ios.o ios/sound_ios.o ios/gamecenter_ios.o ios/net_ios.o
	MLPPOPT += -DGLES -DIOS
	LIBFLAGS = -cclib '-framework\ Foundation' \
						 -cclib '-framework\ UIKit' \
						 -cclib '-framework\ QuartzCore' \
						 -cclib '-framework\ CoreGraphics' \
						 -cclib '-framework\ OpenGLES' \
						 -cclib '-framework\ AudioToolbox' \
						 -cclib '-framework\ OpenAL' \
						 -cclib '-framework\ GameKit'
else
	ifeq ($(PLATFORM),android)
		gl = gl/es
		MLPPOPT += -DGLES -DANDROID 
		MLCOPTS += -D__ANDROID__
		MOBJS += mlwrapper.o android/mlwrapper_android.o android/texture_android.o
		GLPARAM = -D__ANDROID__
		LIBFLAGS = -cclib '-lGLESv1_CM' -cclib '-llog' -cclib '-lz' -cclib '-lpng'
	else
		gl = gl/2.1
		MOBJS += sdl/sdl_stub.o sdl/sdl_image_stub.o sdl/texture_sdl.o
		BMLSOURCES = sdl/sdl.ml sdl/sdl_image.ml 
		AMLSOURCES = sdl/sdl_run.ml
		MLOBJSFLAGS = -I sdl
		MLPPOPT += -DSDL
		MLCOMPFLAGS += -package curl,threads -thread
		ifeq ($(OS),macos)
			LIBFLAGS = -cclib '-framework\ Cocoa' -cclib '-lSDL' -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-framework\ OpenGL'
		else
			LIBFLAGS = -cclib '-lSDL' -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-lGL'
		endif
		GLPARAM = -DGL_GLEXT_PROTOTYPES -fPIC
	endif
endif


MOBJS += $(gl)/gl_stub.o 

MLSOURCES = $(gl)/gl.ml $(BMLSOURCES) Debug.ml ProfTimer.ml  WeakMemo.ml Dictionary.ml LightCommon.ml Ev.ml EventDispatcher.ml Point.ml Rectangle.ml Matrix.ml RenderSupport.ml \
					DisplayObject.ml Sprite.ml Quad.ml Texture.ml TextureAtlas.ml Image.ml CompiledSprite.ml Touch.ml BitmapFont.ml TextField.ml FPS.ml Timers.ml Timer.ml \
					Stage.ml Button.ml MovieClip.ml Tween.ml Sound.ml GameCenter.ml LocalStorage.ml URLLoader.ml $(AMLSOURCES) Lightning.ml 
$(gl)/gl_stub.o: $(gl)/gl_stub.c
	$(OCAMLOPT) -verbose -g $(if $(GLPARAM),$(patsubst %,-ccopt %,$(GLPARAM))) -ccopt '-o $(gl)/gl_stub.o' -c $(gl)/gl_stub.c

MLCONTAINERS = containers/MList.ml containers/HSet.ml containers/PriorityQueue.ml containers/WeakHashtbl.ml
MLUTILS = utils/UrlEncoding.ml


#XMLMFILES = TextureAtlas.ml BitmapFont.ml LightCommon.ml MovieClip.ml
#$(XMLMFILES:.ml=.cmo) $(XMLMFILES:.ml=.cmx) $(XMLMFILES:.ml=.cmi): MLFLAGS += -package xmlm

MLCONTAINERSOBJS = $(MLCONTAINERS:.ml=.cmx)
MLUTILSOBJS = $(MLUTILS:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmx)
$(MLOBJS): MLFLAGS += -package xmlm -I $(gl) $(MLOBJSFLAGS)
$(MLOBJS): Debug.cmx

$(MLOBJS) MLDepend.$(PLATFORM): syntax/pa_debug.cmo 
$(MLOBJS) MLDepend.$(PLATFORM): MLPPOPT += syntax/pa_debug.cmo 
-include debug.conf
	
lightning.cmxa: MLDepend.$(PLATFORM) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o lightning $(MOBJS) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MLOBJS) $(LIBFLAGS) 

MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep $(MLFLAGS) -I containers $(MLCONTAINERS:.ml=.mli) $(MLCONTAINERS) > MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLFLAGS) -I containers -I utils $(MLUTILS:.ml=.mli) $(MLUTILS) >> MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLFLAGS) -I $(gl) $(MLOBJSFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) *.mli $(MLSOURCES) >> MLDepend.$(PLATFORM)


doc:
	mkdir -p docs
	$(OCAMLFIND) ocamldoc -short-functors -html -d docs $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLFLAGS) \
		containers/MList.ml containers/HSet.mli PriorityQueue.mli WeakHashtbl.mli WeakMemo.mli LightCommon.ml Event.ml EventDispatcher.mli Point.ml Rectangle.ml Matrix.ml DisplayObjectT.ml DisplayObject.mli Sprite.mli Quad.mli \
		Texture.mli TextureAtlas.mli Image.mli CompiledSprite.mli Touch.ml BitmapFont.mli TextField.mli Stage.mli Button.mli MovieClip.mli Tween.mli GameCenter.mli LocalStorage.mli Lightning.ml


.DEFAULT_GOAL := release

.PHONY : clean
clean: 
	rm -f *.o *.cm[iox] *.a *.cmxa *.so ios/*.o sdl/*.cmx sdl/*.o sdl/*.cmi containers/*.cmi containers/*.cmx containers/*.cmo containers/*.o $(gl)/*.o $(gl)/*.cmx $(gl)/*.cmi *.html *.css MLDepend.* syntax/*.cmo syntax/*.cmi utils/*.cmi utils/*.cmx utils/*.a 

-include MLDepend.$(PLATFORM)
