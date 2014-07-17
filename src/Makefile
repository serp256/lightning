include ../Makefile.common

CFLAGS += -I .

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

#MOBJS = bezier.o inline_shaders.o light_common.o texture_common.o texture_pvr.o texture_async_loader.o renderbuffer_stub.o filters_stub.o render_stub.o
MOBJS = bezier.o inline_shaders.o light_common.o texture_common.o texture_pvr.o texture_async_loader.o rects-bin.o rendertex/common.o rendertex/shared.o rendertex/dedicated.o rendertex/stubs.o filters_stub.o render_stub.o

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
MLFLAGS +=  -package ojson,extlib,redspell.syntax.debug -I containers -I utils
MLDEPFLAGS =

byte: lightning.cma remote-notifications.cma tapjoy.cma mobileapptracking.cma flurry.cma sponsorpay.cma facebook.cma chartboost.cma appflood.cma supersonic.cma twitter.cma instagram.cma whatsapp.cma appsflyer.cma NativeVk.cma social_byte
native: MLDEPFLAGS += -native
native: lightning.cmxa remote-notifications.cmxa tapjoy.cmxa flurry.cmxa chartboost.cmxa appflood.cmxa mobileapptracking.cmxa supersonic.cmxa sponsorpay.cmxa facebook.cmxa twitter.cmxa instagram.cmxa whatsapp.cmxa appsflyer.cmxa NativeVk.cmxa social_native
syntax: syntax/pa_prop.cmo


KAZMATHOBJS = utility.o vec2.o vec4.o vec3.o mat3.o quaternion.o mat4.o neon_matrix_impl.o GL/mat4stack.o GL/matrix.o
KAZMATH = $(patsubst %,kazmath/%,$(KAZMATHOBJS))
MLPPOPT = syntax/pa_platform.cmo

SYNTAX = syntax/pa_prop.cmo syntax/pa_platform.cmo
$(SYNTAX): MLFLAGS = -package camlp4,camlp4.lib,camlp4.quotations.r,camlp4.extend,camlp4.macro -syntax camlp4r 



ifeq ($(PLATFORM),IOS)
	MOBJS += mlwrapper.o ios/OpenUDID.o ios/mlwrapper_ios.o mobile_res.o ios/LightActivityIndicator.o ios/LightView.o ios/LightViewController.o ios/LightAppDelegate.o ios/LightDownloaderDelegate.o ios/LightImageLoader.o ios/common_ios.o ios/texture_ios.o ios/texture_save.o ios/sound_ios.o ios/gamecenter_ios.o ios/net_ios.o ios/local_notif.o ios/motion.o ios/hardware_ios.o ios/copy_paste.o
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
						 #-cclib '-framework\ FacebookSDK'
	#CFLAGS += -Fsocial/facebook/ios/FacebookSDK
	else
	ifeq ($(PLATFORM),ANDROID)
		CFLAGS += -I android -I android/native_activity
		MLCOPTS += -D__ANDROID__
		MOBJS += mlwrapper.o mobile_res.o net_curl.o texture_load.o texture_save.o android/native_activity/android_native_app_glue.o android/native_activity/engine.o android/native_activity/lightning_android.o android/native_activity/expansions_android.o android/native_activity/payments_android.o android/native_activity/gamecenter_android.o android/native_activity/sound_android.o android/native_activity/curl_imgloader_android.o android/native_activity/curl_filedownloader_android.o android/native_activity/notifications_android.o android/native_activity/keyboard_android.o android/native_activity/camlwrapper_android.o  android/native_activity/main.o android/native_activity/vibration_android.o android/mlwrapper_android.o android/texture_android.o
		GLPARAM = -D__ANDROID__
		LIBFLAGS = -cclib -landroid -cclib -lOpenSLES -cclib -lEGL -cclib -llog -cclib -lz -cclib '-lGLESv2' -cclib '-llog' -cclib '-lz' -cclib '-lpng' -cclib '-ljpeg' -cclib '-lcurl' -cclib '-lssl' -cclib '-lcrypto'
	else
	ifeq ($(PLATFORM),PC)
		MOBJS += net_curl.o pc/glut_stub.o texture_load.o texture_save.o pc/texture_pc.o
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
CFLAGS += -D$(PLATFORM) -DOS$(OS)

$(SYNTAX): MLPPOPT := -D$(PLATFORM)

MLSOURCES = $(BMLSOURCES) Hardware.ml LocalNotifications.ml Keyboard.ml Motion.ml ProfTimer.ml  WeakMemo.ml Rectangle.ml Point.ml Matrix.ml LightCommon.ml Ev.ml EventDispatcher.ml Render.ml Filters.ml \
					DisplayObject.ml GLPrograms.ml Shape.ml Quad.ml Texture.ml  RenderTexture.ml Image.ml AtlasNode.ml \
					TextureAtlas.ml Atlas.ml Clip.ml BitmapFont.ml Sprite.ml TLF.ml Timers.ml Timer.ml  LightLib.ml BezierObject.ml \
					Touch.ml Stage.ml Tween.ml Sound.ml GameCenter.ml Vibration.ml URLLoader.ml KVStorage.ml Payment.ml $(AMLSOURCES) RenderStage.ml Lightning.ml

#Texture.cmo Texture.cmx: MLFLAGS += -package threads -thread

$(gl)/gl_stub.o: $(gl)/gl_stub.c
	$(OCAMLOPT) -verbose -g $(if $(GLPARAM),$(patsubst %,-ccopt %,$(GLPARAM))) -ccopt '-o $(gl)/gl_stub.o' -c $(gl)/gl_stub.c

MLCONTAINERS = containers/MList.ml containers/Vector.ml containers/HSet.ml containers/MHashtbl.ml containers/PriorityQueue.ml containers/WeakHashtbl.ml containers/ThreadSafeQueue.ml
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
$(MLOBJS) $(MLOBJSB) MLDepend.$(PLATFORM): syntax/pa_platform.cmo
include debug.conf
	

lightning.cma: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MOBJS) $(MLOBJSB)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) $(MLCONTAINERSOBJSB) $(MLUTILSOBJSB) $(MLOBJSB) $(LIBFLAGS) 

lightning.cmxa: MLDepend.$(PLATFORM) $(KAZMATH) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o lightning $(KAZMATH) $(MOBJS) $(MLCONTAINERSOBJS) $(MLUTILSOBJS) $(MLOBJS) $(LIBFLAGS) 
	
remote-notifications.cma:
	make -C plugins/remote-notifications remote-notifications.cma

remote-notifications.cmxa:
	make -C plugins/remote-notifications remote-notifications.cmxa


tapjoy.cma:
	make -C plugins/tapjoy tapjoy.cma

tapjoy.cmxa:
	make -C plugins/tapjoy tapjoy.cmxa

facebook.cma:
	make -C plugins/facebook facebook.cma

facebook.cmxa:
	make -C plugins/facebook facebook.cmxa

sponsorpay.cma:
	make -C plugins/sponsorpay sponsorpay.cma

sponsorpay.cmxa:
	make -C plugins/sponsorpay sponsorpay.cmxa

# flurry.cma:
# 	make -C flurry flurry.cma

# flurry.cmxa:
# 	make -C flurry flurry.cmxa

social_byte:
	make -C social byte

social_native:
	make -C social native

mopub.cmxa:
	make -C plugins/mopub mopub.cmxa

mobileapptracking.cma:
	make -C plugins/mobileapptracking mobileapptracking.cma

mobileapptracking.cmxa:
	make -C plugins/mobileapptracking mobileapptracking.cmxa

flurry.cma:
	make -C plugins/flurry flurry.cma

flurry.cmxa:
	make -C plugins/flurry flurry.cmxa

chartboost.cma:
	make -C plugins/chartboost chartboost.cma

chartboost.cmxa:
	make -C plugins/chartboost chartboost.cmxa

appflood.cma:
	make -C plugins/appflood appflood.cma

appflood.cmxa:
	make -C plugins/appflood appflood.cmxa

supersonic.cma:
	make -C plugins/supersonic supersonic.cma

appsflyer.cma:
	make -C plugins/appsflyer appsflyer.cma

supersonic.cmxa:
	make -C plugins/supersonic supersonic.cmxa

twitter.cma:
	make -C plugins/twitter twitter.cma

twitter.cmxa:
	make -C plugins/twitter twitter.cmxa

instagram.cma:
	make -C plugins/instagram instagram.cma

instagram.cmxa:
	make -C plugins/instagram instagram.cmxa

whatsapp.cma:
	make -C plugins/whatsapp whatsapp.cma

whatsapp.cmxa:
	make -C plugins/whatsapp whatsapp.cmxa

NativeVk.cma:
	make -C plugins/vk NativeVk.cma

NativeVk.cmxa:
	make -C plugins/vk NativeVk.cmxa

appsflyer.cmxa:
	make -C plugins/appsflyer appsflyer.cmxa

MLDepend.$(PLATFORM):
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers $(MLCONTAINERS:.ml=.mli) $(MLCONTAINERS) > MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  -I containers -I utils $(MLUTILS:.ml=.mli) $(MLUTILS) >> MLDepend.$(PLATFORM)
	$(OCAMLFIND) ocamldep $(MLDEPFLAGS) $(MLFLAGS)  $(MLOBJSFLAGS) $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLSOURCES:.ml=.mli) RenderFilters.ml  $(MLSOURCES) >> MLDepend.$(PLATFORM)


doc:
	mkdir -p docs
	$(OCAMLFIND) ocamldoc -short-functors -html -d docs $(if $(MLPPOPT),$(patsubst %,-ppopt %,$(MLPPOPT))) $(MLFLAGS) \
		containers/MList.ml containers/Vector.mli containers/HSet.mli containers/PriorityQueue.mli containers/WeakHashtbl.mli WeakMemo.mli LightCommon.mli Ev.mli EventDispatcher.mli Point.ml Rectangle.ml Matrix.ml DisplayObject.mli Sprite.mli Quad.mli \
		Texture.mli TextureAtlas.mli Image.mli Touch.ml BitmapFont.mli Clip.mli LightLib.mli TLF.mli Stage.mli GameCenter.mli Lightning.mli


.DEFAULT_GOAL := debug

.PHONY : clean
clean: 
	rm -f *.o rendertex/*.o *.cm[iox] *.a *.cmxa *.so *.cmo ios/*.o glut/*.cmx glut.*.cmo glut/*.o glut/*.cmi sdl/*.cmx sdl/*.cmo sdl/*.o sdl/*.cmi containers/*.cmi containers/*.cmx containers/*.cmo containers/*.o $(gl)/*.o $(gl)/*.cmx $(gl)/*.cmi *.html *.css MLDepend.* syntax/*.cmo syntax/*.cmi utils/*.cmi utils/*.cmx utils/*.cmo utils/*.a kazmath/*.o kazmath/GL/*.o android/*.o pc/*.o
	$(MAKE) -C plugins/chartboost clean
	$(MAKE) -C social clean
	$(MAKE) -C plugins/tapjoy clean
	$(MAKE) -C plugins/facebook clean
	$(MAKE) -C plugins/mobileapptracking clean
	$(MAKE) -C plugins/flurry clean
	$(MAKE) -C plugins/appflood clean
	$(MAKE) -C plugins/sponsorpay clean
	$(MAKE) -C plugins/supersonic clean
	$(MAKE) -C plugins/twitter clean
	$(MAKE) -C plugins/instagram clean
	$(MAKE) -C plugins/whatsapp clean
	$(MAKE) -C plugins/appsflyer clean
	$(MAKE) -C plugins/remote-notifications clean
	$(MAKE) -C plugins/vk clean

-include MLDepend.$(PLATFORM)
