include ../../Makefile.common

#CFLAGS += -I . 

MLFLAGS += -package ojson,extlib

#.o: %.c
#	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLFLAGS += -I .. -I ../utils -I oauth

#ifeq ($(PLATFORM),IOS)
#FAKELIBS  =
#CFLAGS  += -DDEBUG -DIOS -Iios
#MLCOPTS += -DIOS
#MOBJS   +=  
            
#MLPPOPT += -DGLES -DIOS
#LIBFLAGS = -cclib '-framework\ Foundation' \
#		   -cclib '-framework\ UIKit' \
#		   -cclib '-framework\ QuartzCore' \
#		   -cclib '-framework\ CoreGraphics' 
#endif

oauth_native:
	make -C oauth oauth.cmxa

oauth_byte:
	make -C oauth oauth.cma

fb_native:
	make -C facebook fbconnect.cmxa

fb_byte:
	make -C facebook fbconnect.cma

native: oauth_native fb_native SNTypes.cmi OK.cmi OK.cmx MM.cmi MM.cmx VK.cmi VK.cmx
byte:   oauth_byte fb_byte SNTypes.cmi  OK.cmi OK.cmo MM.cmi MM.cmo VK.cmi VK.cmo

.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o
	make -C oauth clean
	make -C facebook clean

