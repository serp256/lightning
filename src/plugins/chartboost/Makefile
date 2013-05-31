include ../../../Makefile.common

MLSOURCES = ChartBoost.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLPPOPT += ../../syntax/pa_platform.cmo

ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -DLDEBUG -I../../ -I../../android -I./android -I../common
COBJS  += android/chartboost_android.o

chartboost.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
		$(OCAMLMKLIB) -verbose -o chartboost $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

chartboost.cma: $(IFACES) $(MOBJS) $(CLOBJS)
		$(OCAMLMKLIB) -verbose -o chartboost $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

endif

clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o ios/*.o android/*.o