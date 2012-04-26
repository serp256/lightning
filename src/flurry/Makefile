include ../../Makefile.common

CFLAGS += -I . 

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = FlurryAnalytics.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios -Iios/FlurryAnalytics
MLCOPTS += -DIOS
MOBJS   +=  ios/flurry_wrapper.o \
            ios/FlurryAnalytics/FlurryAnalytics.o \
            ios/FlurryAnalytics/FlurryConnectionDelegate.o\
            ios/FlurryAnalytics/FlurryEvent.o\
            ios/FlurryAnalytics/FlurryFileCache.o\
            ios/FlurryAnalytics/FlurryHeartBeater.o\
            ios/FlurryAnalytics/FlurryHTTPEater.o\
            ios/FlurryAnalytics/FlurryHTTPResponse.o\
            ios/FlurryAnalytics/FlurryImageCache.o\
            ios/FlurryAnalytics/FlurryPageViewDelegate.o\
            ios/FlurryAnalytics/FlurryProtocolData.o\
            ios/FlurryAnalytics/FlurrySession.o\
            ios/FlurryAnalytics/FlurryUtil.o\
            ios/FlurryAnalytics/FlurryAutoIncrement.o

            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' \
   

flurry.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o flurry $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

flurry.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o flurry $(MOBJS) $(MLOBJS) $(LIBFLAGS) 
else

flurry.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o flurry.cmxa $(MLOBJSN)

flurry.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o flurry.cma $(MLOBJS)

endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o

