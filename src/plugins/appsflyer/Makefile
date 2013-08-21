
include ../../../Makefile.common

MLSOURCES = AppsFlyer.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)
CFLAGS += -DLDEBUG 

MLPPOPT += ../../syntax/pa_platform.cmo 


ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -I../../ -I../../android -I./android 
COBJS  += android/af_android.o
MLPPOPT += -DANDROID

else
ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Fios 
COBJS   += ios/af_ios.o
MLPPOPT += -DIOS

LIBFLAGS += -cclib '-weak_framework\ AdSupport' \
						-cclib -lappsflyer-sdk

else

MLPPOPT += -DPC

endif
endif

ifeq ($(PLATFORM),PC)
	
appsflyer.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o appsflyer.cmxa $(MLOBJSN)

appsflyer.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o appsflyer.cma $(MLOBJS)

else
appsflyer.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	  $(OCAMLMKLIB) -o appsflyer $(COBJS) $(MLOBJSN) $(LIBFLAGS)

appsflyer.cma: $(IFACES) $(COBJS) $(MLOBJS)
	  $(OCAMLMKLIB) -o appsflyer $(COBJS) $(MLOBJS) $(LIBFLAGS)


endif

clean:
	rm -f *.a *.o *.so android/*.o ios/*.o *.cmx *.cmo *.cmxa *.cma *.cmi
