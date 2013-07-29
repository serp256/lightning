
include ../../../Makefile.common

MLSOURCES = MobileAppTracking.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)
CFLAGS += -DLDEBUG 

MLPPOPT += ../../syntax/pa_platform.cmo 


ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -I../../ -I../../android -I./android 
COBJS  += android/mobileapptracker_android.o
MLPPOPT += -DANDROID

else
ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Fios 
COBJS   += ios/mobileapptracker_ios.o
MLPPOPT += -DIOS

LIBFLAGS = -cclib '-framework\ Foundation' \
       -cclib '-framework\ UIKit' \
       -cclib '-framework\ MobileAppTracker' \
			 -cclib '-framework\ MobileCoreServices'
else

MLPPOPT += -DPC

endif
endif

ifeq ($(PLATFORM),PC)
	
mobileapptracking.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o mobileapptracking.cmxa $(MLOBJSN)

mobileapptracking.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o mobileapptracking.cma $(MLOBJS)

else
mobileapptracking.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	  $(OCAMLMKLIB) -o mobileapptracking $(COBJS) $(MLOBJSN) $(LIBFLAGS)

mobileapptracking.cma: $(IFACES) $(COBJS) $(MLOBJS)
	  $(OCAMLMKLIB) -o mobileapptracking $(COBJS) $(MLOBJS) $(LIBFLAGS)


endif

clean:
	rm -f *.a *.o *.so android/*.o ios/*.o *.cmx *.cmo *.cmxa *.cma *.cmi
