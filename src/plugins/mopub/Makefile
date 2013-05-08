
include ../../../Makefile.common

MLSOURCES = MoPub.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)


ifeq ($(PLATFORM),ANDROID)

CFLAGS += -DANDROID -DLDEBUG -I../ -I../android -I./android 
COBJS  += android/mopub_android.o
#$(IFACES) $


mopub.cmxa: $(COBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o mopub $(COBJS) $(MLOBJSN) $(LIBFLAGS) 

mopub.cma: $(IFACES) $(MOBJS) $(CLOBJS) 
	$(OCAMLMKLIB) -verbose -o mopub $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

endif
