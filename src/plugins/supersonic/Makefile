include ../../../Makefile.common

MLSOURCES = Supersonic.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLPPOPT += ../../syntax/pa_platform.cmo

ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -DLDEBUG -I../../ -I../../android -I./android -I../common
COBJS  += android/supersonic_android.o

supersonic.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
		$(OCAMLMKLIB) -verbose -o supersonic $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

supersonic.cma: $(IFACES) $(MOBJS) $(CLOBJS)
		$(OCAMLMKLIB) -verbose -o supersonic $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else

supersonic.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o supersonic.cmxa $(MLOBJSN)

supersonic.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o supersonic.cma $(MLOBJS)

endif

clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o ios/*.o android/*.o
