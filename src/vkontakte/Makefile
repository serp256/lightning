include ../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = VK.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios
MLCOPTS += -DIOS
MOBJS   +=  ios/vk_wrapper.o ios/VKAuth.o
            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' 

vk.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o vk $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

vk.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o vk $(MOBJS) $(MLOBJS) $(LIBFLAGS) 
else

vk.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o vk.cmxa $(MLOBJSN)

vk.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o vk.cma $(MLOBJS)

endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o

