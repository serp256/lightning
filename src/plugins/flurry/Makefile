include ../../../Makefile.common

MLSOURCES = Flurry.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLPPOPT += ../../syntax/pa_platform.cmo

ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -DLDEBUG -I../../ -I../../android -I./android -I../common
COBJS  += android/flurry_android.o

endif


ifeq ($(PLATFORM),ANDROID)

flurry.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
		$(OCAMLMKLIB) -verbose -o flurry $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

flurry.cma: $(IFACES) $(MOBJS) $(CLOBJS)
		$(OCAMLMKLIB) -verbose -o flurry $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else


flurry.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o flurry.cmxa $(MLOBJSN)

flurry.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o flurry.cma $(MLOBJS)


endif




clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o ios/*.o android/*.o
