include ../../../Makefile.common

MLSOURCES = Supersonic.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLPPOPT += ../../syntax/pa_platform.cmo

ifeq ($(PLATFORM),ANDROID)
CFLAGS += -DANDROID -DLDEBUG -I../../ -I../../android -I./android -I../common
COBJS  += android/supersonic_android.o
endif

ifeq ($(PLATFORM),IOS)
CFLAGS += -I ./ios -I../../ios
COBJS  += ios/supersonic_ios.o
LIBFLAGS += -framework CoreTelephony -framework AdSupport -lsupersonic-sdk
endif

ifeq ($(PLATFORM),PC)

supersonic.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o supersonic.cmxa $(MLOBJSN)

supersonic.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o supersonic.cma $(MLOBJS)

else

supersonic.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
		$(OCAMLMKLIB) -verbose -o supersonic $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

supersonic.cma: $(IFACES) $(MOBJS) $(CLOBJS)
		$(OCAMLMKLIB) -verbose -o supersonic $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

endif

clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o ios/*.o android/*.o
