
include ../../../Makefile.common

MLSOURCES = MobileAppTracking.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
#IFACES = $(MLSOURCES:.ml=.cmi)
#CFLAGS += -DLDEBUG 


ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -I../../ -I../../android -I./android 
COBJS  += android/mobileapptracker_android.o

else
ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Fios 
COBJS   += ios/mobileapptracker_ios.o

LIBFLAGS = -cclib '-framework\ Foundation' \
       -cclib '-framework\ UIKit' \
       -cclib '-framework\ MobileAppTracker' \
			 -cclib '-framework\ MobileCoreServices'


endif
endif

mobileapptracking.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	  $(OCAMLMKLIB) -verbose -o mobileapptracking $(COBJS) $(MLOBJSN) $(LIBFLAGS)

mobileapptracking.cma: $(IFACES) $(COBJS) $(MLOBJS)
	  $(OCAMLMKLIB) -verbose -o mobileapptracking $(COBJS) $(MLOBJS) $(LIBFLAGS)

clean:
	rm -f *.a *.o *.so android/*.o ios/*.o *.cmx *.cmo *.cmxa *.cma
