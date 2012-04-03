include ../../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = OAuth.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ../.. -I ../../utils

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios
MLCOPTS += -DIOS
MOBJS   +=  ios/oauth_wrapper.o ios/OAuth.o
            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' 

oauth.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o oauth $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

oauth.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o oauth $(MOBJS) $(MLOBJS) $(LIBFLAGS) 
else

oauth.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o oauth.cmxa $(MLOBJSN)

oauth.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o oauth.cma $(MLOBJS)

endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o

