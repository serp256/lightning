include ../Makefile.common


CFLAGS += -I .

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<


GLPARAM = 

MOBJS = texture_common.o filters_stub.o render_stub.o
MLOBJSFLAGS = 
MLFLAGS +=  -package ojson,extlib -I containers -I utils
MLDEPFLAGS =

byte: lightning.cma fbconnect.cma vk.cma
native: MLDEPFLAGS += -native
native: lightning.cmxa fbconnect.cmxa vk.cmxa
syntax: syntax/pa_prop.cmo


KAZMATHOBJS = utility.o vec2.o vec4.o vec3.o mat3.o quaternion.o mat4.o neon_matrix_impl.o GL/mat4stack.o GL/matrix.o
KAZMATH = $(patsubst %,kazmath/%,$(KAZMATHOBJS))
MLPPOPT = syntax/pa_debug.cmo

SYNTAX = syntax/pa_prop.cmo syntax/pa_debug.cmo
$(SYNTAX): MLFLAGS = -package camlp4,camlp4.lib,camlp4.quotations.r,camlp4.extend,camlp4.macro -syntax camlp4r 
Debug.cmx: MLFLAGS += -package unix
$(SYNTAX): OCAMLC = ocamlfind ocamlc



ifeq ($(PLATFORM),IOS)
	gl = gl/es
	#CFLAGS +=  -DDEBUG -DIOS
	#MLCOPTS += -DIOS
	MOBJS += mlwrapper.o ios/mlwrapper_ios.o ios/LightActivityIndicator.o ios/LightView.o ios/LightViewController.o ios/common_ios.o ios/texture_ios.o ios/sound_ios.o ios/gamecenter_ios.o ios/net_ios.o
	#MLPPOPT += -DGLES -DIOS
	LIBFLAGS = -cclib '-framework\ Foundation' \
						 -cclib '-framework\ UIKit' \
						 -cclib '-framework\ QuartzCore' \
						 -cclib '-framework\ CoreGraphics' \
						 -cclib '-framework\ OpenGLES' \
						 -cclib '-framework\ AudioToolbox' \
						 -cclib '-framework\ OpenAL' \
						 -cclib '-framework\ GameKit'
else
	ifeq ($(PLATFORM),ANDROID)
		gl = gl/es
		#MLPPOPT += -DGLES -DANDROID 
		MLCOPTS += -D__ANDROID__
		MOBJS += mlwrapper.o android/mlwrapper_android.o android/texture_android.o
		GLPARAM = -D__ANDROID__
		LIBFLAGS = -cclib '-lGLESv2' -cclib '-llog' -cclib '-lz' -cclib '-lpng' -cclib '-ljpeg'
	else
		CFLAGS += $(shell ${SDLCONFIG} --cflags)
		gl = gl/2.1
		MOBJS += sdl/sdl_stub.o sdl/sdl_image_stub.o 
		BMLSOURCES = sdl/sdl.ml sdl/sdl_image.ml 
		AMLSOURCES = sdl/sdl_run.ml
		MLOBJSFLAGS = -I sdl
		#MLPPOPT += -DSDL
		MLCOMPFLAGS += -package curl,threads -thread
		SDLFLAGS = $(shell ${SDLCONFIG} --libs)
		ifeq ($(OS),macos)
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -cclib '-framework\ Cocoa'  -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-framework\ OpenGL'
		else
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-lGL'
		endif
		GLPARAM = -DGL_GLEXT_PROTOTYPES -fPIC
	endif
endif


MLPPOPT += -D$(PLATFORM)
MLCOPTS += -D$(PLATFORM)
CFLAGS += -D$(PLATFORM)

$(SYNTAX) Debug.cmx Debug.cmo: MLPPOPT := -D$(PLATFORM)

MLSOURCES = $(BMLSOURCES) ProfTimer.ml  WeakMemo.ml LightCommon.ml Ev.ml EventDispatcher.ml Point.ml Rectangle.ml Matrix.ml Render.ml Filters.ml \
					DisplayObject.ml GLPrograms.ml Quad.ml Texture.ml TextureAtlas.ml Image.ml AtlasNode.ml Atlas.ml Touch.ml BitmapFont.ml TLF.ml Timers.ml Timer.ml Sprite.ml \
					Stage.ml Tween.ml Sound.ml GameCenter.ml LocalStorage.ml URLLoader.ml KVStorage.ml Payment.ml $(AMLSOURCES) Lightning.ml 

$(gl)/gl_stub.o: $(gl)/gl_stub.c
	$(OCAMLOPT) -verbose -g $(if $(GLPARAM),$(patsubst %,-ccopt %,$(GLPARAM))) -ccopt '-o $(gl)/gl_stub.o' -c $(gl)/gl_stub.c

MLCONTAINERS = containers/MList.ml containers/HSet.ml containers/PriorityQueue.ml containers/WeakHashtbl.ml
MLUTILS = utils/UrlEncoding.ml


#XMLMFILES = TextureAtlas.ml BitmapFont.ml LightCommon.ml MovieClip.ml
#$(XMLMFILES:.ml=.cmo) $(XMLMFILES:.ml=.cmx) $(XMLMFILES:.ml=.cmi): MLFLAGS += -package xmlm

MLCONTAINERSOBJS = $(MLCONTAINERS:.ml=.cmx)
MLCONTAINERSOBJSB = $(MLCONTAINERS:.ml=.cmo)
MLUTILSOBJS = $(MLUTILS:.ml=.cmx)
MLUTILSOBJSB = $(MLUTILS:.ml=.cmo)
MLOBJS = $(MLSOURCES:.ml=.cmx)
MLOBJSB = $(MLSOURCES:.ml=.cmo)
$(MLOBJS) $(MLOBJSB): MLFLAGS += -package xmlm  $(MLOBJSFLAGS)
$(MLOBJS): Debug.cmx
$(MLOBJSB): Debug.cmo

$(MLOBJS) $(MLOBJSB) MLDepend.$(PLATFORM): syntax/pa_debug.cmo 
-include debug.conf
	

lightning.cma: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MOBJS) $(MLOBJSB)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) Debug.cmo $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MLOBJSB) $(LIBFLAGS) 

lightning.cmxa: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) Debug.cmx $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MLOBJS) $(LIBFLAGS) 

fbconnect.cma:
	make -C facebook fbconnect.cma

fbconnect.cmxa:
	make -C facebook fbconnect.cmxa

vk.cma:
	make -C vkontakte vk.cma

vk.cmxa:
	make -C vkontakte vk.cmxa


MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers $(MLCONTAINERS:.ml=.mli) $(MLCONTAINERS) > MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers -I utils $(MLUTILS:.ml=.mli) $(MLUTILS) >> MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  $(MLOBJSFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLSOURCES:.ml=.mli) RenderFilters.ml $(MLSOURCES) >> MLDepend.$(PLATFORM)
# $(OCAMLFIND) ocamldep $(MLFLAGS) -I $(gl) $(MLOBJSFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) *.mli $(MLSOURCES) >> MLDepend.$(PLATFORM)


doc:
	mkdir -p docs
	$(OCAMLFIND) ocamldoc -short-functors -html -d docs $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLFLAGS) \
		containers/MList.ml containers/HSet.mli PriorityQueue.mli WeakHashtbl.mli WeakMemo.mli LightCommon.ml Event.ml EventDispatcher.mli Point.ml Rectangle.ml Matrix.ml DisplayObjectT.ml DisplayObject.mli Sprite.mli Quad.mli \
		Texture.mli TextureAtlas.mli Image.mli CompiledSprite.mli Touch.ml BitmapFont.mli TextField.mli Stage.mli Button.mli MovieClip.mli Tween.mli GameCenter.mli LocalStorage.mli Lightning.ml


.DEFAULT_GOAL := release

.PHONY : clean
clean: 
	rm -f *.o *.cm[iox] *.a *.cmxa *.so *.cmo ios/*.o sdl/*.cmx sdl/*.cmo sdl/*.o sdl/*.cmi containers/*.cmi containers/*.cmx containers/*.cmo containers/*.o $(gl)/*.o $(gl)/*.cmx $(gl)/*.cmi *.html *.css MLDepend.* syntax/*.cmo syntax/*.cmi utils/*.cmi utils/*.cmx utils/*.cmo utils/*.a kazmath/*.o kazmath/GL/*.o android/*.o

-include MLDepend.$(PLATFORM)
