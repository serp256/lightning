include ../Makefile.common

CFLAGS += -I .

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MOBJS = light_common.o texture_common.o texture_pvr.o texture_async_loader.o renderbuffer_stub.o filters_stub.o render_stub.o

light_common.o: light_common.h
texture_common.o: texture_common.h light_common.h
texture_async_loader.o: light_common.h texture_common.h 
render_stub.o: light_common.h texture_common.h render_stub.h
filters_stub.o: light_common.h texture_common.h render_stub.h
ios/texture_ios.o: texture_common.h
sdl/texture_sdl.o: texture_common.h
glut/texture_glut.o: texture_common.h
android/texture_android.o: texture_common.h

MLOBJSFLAGS = 
MLFLAGS +=  -package ojson,extlib -I containers -I utils
MLDEPFLAGS =

byte: lightning.cma tapjoy.cma flurry.cma social_byte
native: MLDEPFLAGS += -native
native: lightning.cmxa tapjoy.cmxa flurry.cmxa social_native
syntax: syntax/pa_prop.cmo


KAZMATHOBJS = utility.o vec2.o vec4.o vec3.o mat3.o quaternion.o mat4.o neon_matrix_impl.o GL/mat4stack.o GL/matrix.o
KAZMATH = $(patsubst %,kazmath/%,$(KAZMATHOBJS))
MLPPOPT = syntax/pa_debug.cmo

SYNTAX = syntax/pa_prop.cmo syntax/pa_debug.cmo
$(SYNTAX): MLFLAGS = -package camlp4,camlp4.lib,camlp4.quotations.r,camlp4.extend,camlp4.macro -syntax camlp4r 
Debug.cmx: MLFLAGS += -package unix



ifeq ($(PLATFORM),IOS)
	MOBJS += mlwrapper.o ios/mlwrapper_ios.o ios/LightActivityIndicator.o ios/LightView.o ios/LightViewController.o ios/LightAppDelegate.o ios/LightImageLoader.o ios/common_ios.o ios/texture_ios.o ios/sound_ios.o ios/gamecenter_ios.o ios/net_ios.o ios/local_notif.o ios/motion.o ios/hardware_ios.o ios/copy_paste.o
	LIBFLAGS = -ccopt '-ObjC' -cclib '-framework\ Foundation' \
						 -cclib '-framework\ UIKit' \
						 -cclib '-framework\ QuartzCore' \
						 -cclib '-framework\ CoreGraphics' \
						 -cclib '-framework\ OpenGLES' \
						 -cclib '-framework\ AudioToolbox' \
						 -cclib '-framework\ AVFoundation' \
						 -cclib '-framework\ OpenAL' \
						 -cclib '-framework\ GameKit' \
						 -cclib '-framework\ StoreKit' \
						 -cclib '-framework\ CoreMotion'
	else
	ifeq ($(PLATFORM),ANDROID)
		MLCOPTS += -D__ANDROID__
		MOBJS += mlwrapper.o net_curl.o texture_load.o android/mlwrapper_android.o android/texture_android.o android/payments_android.o android/unzip.o android/ioapi.o android/assets_extractor.o android/curl_extern_loader.o android/keyboard_android.o
		GLPARAM = -D__ANDROID__
		LIBFLAGS = -cclib '-lGLESv2' -cclib '-llog' -cclib '-lz' -cclib '-lpng' -cclib '-ljpeg' -cclib '-lcurl'
	else
	ifeq ($(PLATFORM),PC)
		MOBJS += net_curl.o pc/glut_stub.o texture_load.o pc/texture_pc.o
		BMLSOURCES = pc/glut.ml
		AMLSOURCES = pc/pc_run.ml
		MLOBJSFLAGS = -I pc
		ifeq ($(OS),macos)
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -framework Cocoa  -framework OpenGL -framework GLUT
		else
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -cclib '-lGL' -cclib '-lglut'
		endif
		LIBFLAGS += -lcurl -lpng -ljpeg
		GLPARAM = -DGL_GLEXT_PROTOTYPES -fPIC
	else
		CFLAGS += $(shell ${SDLCONFIG} --cflags)
		MOBJS += net_curl.o sdl/sdl_stub.o sdl/sdl_image_stub.o sdl/texture_sdl.o
		BMLSOURCES = sdl/sdl.ml sdl/sdl_image.ml 
		AMLSOURCES = sdl/sdl_run.ml
		MLOBJSFLAGS = -I sdl
		#MLCOMPFLAGS += -package curl,threads -thread
		SDLFLAGS = $(shell ${SDLCONFIG} --libs)
		ifeq ($(OS),macos)
			#LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -cclib '-framework\ Cocoa'  -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-framework\ OpenGL'
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -framework Cocoa  -lSDL_image -lSDLmain -framework OpenGL
		else
			LIBFLAGS = $(patsubst %,-ccopt %,${SDLFLAGS}) -cclib '-lSDL_image' -cclib '-lSDLmain' -cclib '-lGL'
		endif
		LIBFLAGS += -lcurl
		GLPARAM = -DGL_GLEXT_PROTOTYPES -fPIC
	endif
	endif
endif

pc/pc_run.cmo: MLFLAGS += -package threads -thread
pc/pc_run.cmx: MLFLAGS += -package threads -thread

LIBFLAGS += -cclib '-lz'


MLPPOPT += -D$(PLATFORM)
MLCOPTS += -D$(PLATFORM)
CFLAGS += -D$(PLATFORM)

$(SYNTAX) Debug.cmx Debug.cmo: MLPPOPT := -D$(PLATFORM)

MLSOURCES = $(BMLSOURCES) Hardware.ml LocalNotifications.ml Keyboard.ml Motion.ml ProfTimer.ml  WeakMemo.ml LightCommon.ml Ev.ml EventDispatcher.ml Point.ml Rectangle.ml Matrix.ml Render.ml Filters.ml \
					DisplayObject.ml GLPrograms.ml Quad.ml Texture.ml  RenderTexture.ml Image.ml AtlasNode.ml TextureAtlas.ml Atlas.ml Clip.ml BitmapFont.ml Sprite.ml TLF.ml Timers.ml Timer.ml  LightLib.ml\
					Touch.ml Stage.ml Tween.ml Sound.ml GameCenter.ml URLLoader.ml KVStorage.ml Payment.ml $(AMLSOURCES) FB.ml Lightning.ml

#Texture.cmo Texture.cmx: MLFLAGS += -package threads -thread

$(gl)/gl_stub.o: $(gl)/gl_stub.c
	$(OCAMLOPT) -verbose -g $(if $(GLPARAM),$(patsubst %,-ccopt %,$(GLPARAM))) -ccopt '-o $(gl)/gl_stub.o' -c $(gl)/gl_stub.c

MLCONTAINERS = containers/MList.ml containers/HSet.ml containers/MHashtbl.ml containers/PriorityQueue.ml containers/WeakHashtbl.ml containers/ThreadSafeQueue.ml
MLUTILS = utils/UrlEncoding.ml


#XMLMFILES = TextureAtlas.ml BitmapFont.ml LightCommon.ml MovieClip.ml
#$(XMLMFILES:.ml=.cmo) $(XMLMFILES:.ml=.cmx) $(XMLMFILES:.ml=.cmi): MLFLAGS += -package xmlm

MLCONTAINERSOBJS = $(MLCONTAINERS:.ml=.cmx)
MLCONTAINERSOBJSB = $(MLCONTAINERS:.ml=.cmo)
MLUTILSOBJS = $(MLUTILS:.ml=.cmx)
MLUTILSOBJSB = $(MLUTILS:.ml=.cmo)
MLOBJS = $(MLSOURCES:.ml=.cmx)
MLOBJSB = $(MLSOURCES:.ml=.cmo)
$(MLOBJS) $(MLOBJSB) doc: MLFLAGS += -package xmlm  $(MLOBJSFLAGS)
$(MLOBJS): Debug.cmx
$(MLOBJSB): Debug.cmo

$(MLOBJS) $(MLOBJSB) MLDepend.$(PLATFORM): syntax/pa_debug.cmo 
include debug.conf
	

lightning.cma: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MOBJS) $(MLOBJSB)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) Debug.cmo $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MLOBJSB) $(LIBFLAGS) 

lightning.cmxa: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) Debug.cmx $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MLOBJS) $(LIBFLAGS) 


tapjoy.cma:
	make -C tapjoy tapjoy.cma

tapjoy.cmxa:
	make -C tapjoy tapjoy.cmxa

flurry.cma:
	make -C flurry flurry.cma

flurry.cmxa:
	make -C flurry flurry.cmxa

social_byte:
	make -C social byte

social_native:
	make -C social native

MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers $(MLCONTAINERS:.ml=.mli) $(MLCONTAINERS) > MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers -I utils $(MLUTILS:.ml=.mli) $(MLUTILS) >> MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  $(MLOBJSFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLSOURCES:.ml=.mli) RenderFilters.ml  $(MLSOURCES) >> MLDepend.$(PLATFORM)


doc:
	mkdir -p docs
	$(OCAMLFIND) ocamldoc -short-functors -html -d docs $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLFLAGS) \
		containers/MList.ml containers/HSet.mli containers/PriorityQueue.mli containers/WeakHashtbl.mli WeakMemo.mli LightCommon.mli Ev.mli EventDispatcher.mli Point.ml Rectangle.ml Matrix.ml DisplayObject.mli Sprite.mli Quad.mli \
		Texture.mli TextureAtlas.mli Image.mli Touch.ml BitmapFont.mli Clip.mli LightLib.mli TLF.mli Stage.mli GameCenter.mli Lightning.mli


.DEFAULT_GOAL := debug

.PHONY : clean
clean: 
	rm -f *.o *.cm[iox] *.a *.cmxa *.so *.cmo ios/*.o glut/*.cmx glut.*.cmo glut/*.o glut/*.cmi sdl/*.cmx sdl/*.cmo sdl/*.o sdl/*.cmi containers/*.cmi containers/*.cmx containers/*.cmo containers/*.o $(gl)/*.o $(gl)/*.cmx $(gl)/*.cmi *.html *.css MLDepend.* syntax/*.cmo syntax/*.cmi utils/*.cmi utils/*.cmx utils/*.cmo utils/*.a kazmath/*.o kazmath/GL/*.o android/*.o pc/*.o

-include MLDepend.$(PLATFORM)
