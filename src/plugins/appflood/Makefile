include ../../../Makefile.common

MLSOURCES = Appflood.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLPPOPT += ../../syntax/pa_platform.cmo

ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -DLDEBUG -I../../ -I../../android -I./android -I../common
COBJS  += android/appflood_android.o

appflood.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
		$(OCAMLMKLIB) -verbose -o appflood $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

appflood.cma: $(IFACES) $(MOBJS) $(CLOBJS)
		$(OCAMLMKLIB) -verbose -o appflood $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else

appflood.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o appflood.cmxa $(MLOBJSN)

appflood.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o appflood.cma $(MLOBJS)
endif

clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o ios/*.o android/*.o
