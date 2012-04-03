include ../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLFLAGS += -I .. -I ../utils -I oauth

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios
MLCOPTS += -DIOS
MOBJS   +=  
            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' 
endif

oauth_native:
	make -C oauth oauth.cmxa

oauth_byte:
	make -C oauth oauth.cma

native: oauth_native SNTypes.cmi MM.cmi MM.cmx VK.cmi VK.cmx
byte:   oauth_byte SNTypes.cmi  MM.cmi MM.cmo VK.cmi VK.cmo

.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o
	make -C oauth clean

