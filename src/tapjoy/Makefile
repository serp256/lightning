include ../../Makefile.common

CFLAGS += -I . 

#MLFLAGS += -package ojson,extlib

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = TapjoyConnect.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../syntax/pa_debug.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios 
#-Iios/TapjoyConnect
MLCOPTS += -DIOS
MOBJS   +=  ios/tapjoy_wrapper.o\
				ios/TJCAdManager.o\
				ios/TJCAdRequestHandler.o\
				ios/TJCAdView.o\
				ios/TJCCallsWrapper.o\
				ios/TJCCoreFetcher.o\
				ios/TJCCoreFetcherHandler.o\
				ios/TJCDailyRewardAdManager.o\
				ios/TJCDailyRewardAdRequestHandler.o\
				ios/TJCDailyRewardAdView.o\
				ios/TJCEventTrackingManager.o\
				ios/TJCEventTrackingRequestHandler.o\
				ios/TJCFullScreenAdManager.o\
				ios/TJCFullScreenAdRequestHandler.o\
				ios/TJCFullScreenAdView.o\
				ios/TJCHardwareUtil.o\
				ios/TJCLoadingMainView.o\
				ios/TJCLoadingView.o\
				ios/TJCLog.o\
				ios/TJCNetReachability.o\
				ios/TJCOffersManager.o\
				ios/TJCOffersView.o\
				ios/TJCTBXML.o\
				ios/TJCUIWebPageView.o\
				ios/TJCUserAccountManager.o\
				ios/TJCUserAccountModel.o\
				ios/TJCUserAccountRequestHandler.o\
				ios/TJCUtil.o\
				ios/TJCVideoLayer.o\
				ios/TJCVideoManager.o\
				ios/TJCVideoObject.o\
				ios/TJCVideoRequestHandler.o\
				ios/TJCVideoView.o\
				ios/TJCVideoViewHandler.o\
				ios/TJCViewCommons.o\
				ios/TapjoyConnect.o\
				ios/TapjoyConnectPublisher.o\
#           ios/TapjoyConnect/TapjoyConnect.o 
#            ios/TapjoyConnect/TJCTBXML.o\
#						 ios/TapjoyConnect/TJCOpenUDID.o\
#            ios/TapjoyConnect/TJCAdRequestHandler.o\
#            ios/TapjoyConnect/TJCAdView.o\
#            ios/TapjoyConnect/TJCCallsWrapper.o\
#            ios/TapjoyConnect/TJCCoreFetcher.o\
#            ios/TapjoyConnect/TJCCoreFetcherHandler.o\
#            ios/TapjoyConnect/TJCFeaturedAppDBManager.o\
#            ios/TapjoyConnect/TJCFeaturedAppManager.o\
#            ios/TapjoyConnect/TJCFeaturedAppModel.o\
#            ios/TapjoyConnect/TJCFeaturedAppRequestHandler.o\
#            ios/TapjoyConnect/TJCFeaturedAppView.o\
#            ios/TapjoyConnect/TJCFeaturedAppViewHandler.o\
#            ios/TapjoyConnect/TJCHardwareUtil.o\
#            ios/TapjoyConnect/TJCLoadingView.o\
#            ios/TapjoyConnect/TJCLog.o\
#            ios/TapjoyConnect/TJCNetReachability.o\
#            ios/TapjoyConnect/TJCOffersViewHandler.o\
#            ios/TapjoyConnect/TJCOffersWebView.o\
#            ios/TapjoyConnect/TJCUINavigationBarView.o\
#            ios/TapjoyConnect/TJCUIWebPageView.o\
#            ios/TapjoyConnect/TJCUserAccountManager.o\
#            ios/TapjoyConnect/TJCUserAccountModel.o\
#            ios/TapjoyConnect/TJCUserAccountRequestHandler.o\
#            ios/TapjoyConnect/TJCUtil.o\
#            ios/TapjoyConnect/TJCVideoLayer.o\
#            ios/TapjoyConnect/TJCVideoManager.o\
#            ios/TapjoyConnect/TJCVideoObject.o\
#            ios/TapjoyConnect/TJCVideoRequestHandler.o\
#            ios/TapjoyConnect/TJCVideoView.o\
#            ios/TapjoyConnect/TJCVideoViewHandler.o\
#            ios/TapjoyConnect/TJCViewCommons.o\
            
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' \
		   -cclib '-framework\ CoreTelephony' \
		   -cclib '-framework\ SystemConfiguration' \
		   -cclib '-framework\ MediaPlayer' \
		   -cclib '-lsqlite3'
		   

tapjoy.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o tapjoy $(MOBJS) $(MLOBJSN) $(LIBFLAGS)

tapjoy.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o tapjoy $(MOBJS) $(MLOBJS) $(LIBFLAGS) 
else

tapjoy.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o tapjoy.cmxa $(MLOBJSN)

tapjoy.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o tapjoy.cma $(MLOBJS)

endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/tapjoy_wrapper.o

