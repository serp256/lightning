include ../../Makefile.common

#CFLAGS += -I . 

MLFLAGS += -package ojson,extlib,redspell.syntax.debug

#.o: %.c
#	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLFLAGS += -I .. -I ../utils -I oauth

#ifeq ($(PLATFORM),IOS)
#FAKELIBS  =
#CFLAGS  += -DDEBUG -DIOS -Iios
#MLCOPTS += -DIOS
#MOBJS   +=  
            
MLPPOPT += ../syntax/pa_platform.cmo -enable-debug default
#LIBFLAGS = -cclib '-framework\ Foundation' \
#		   -cclib '-framework\ UIKit' \
#		   -cclib '-framework\ QuartzCore' \
#		   -cclib '-framework\ CoreGraphics' 
#endif

oauth_native:
	make -C oauth oauth.cmxa

oauth_byte:
	make -C oauth oauth.cma

#fb_native:
#	make -C facebook fbconnect.cmxa
fb_native:
	make -C facebook fb.cmxa

fb_byte:
	make -C facebook fb.cma

native: oauth_native fb_native SNTypes.cmi OK.cmi OK.cmx MM.cmi MM.cmx VK.cmi VK.cmx
byte:   oauth_byte fb_byte SNTypes.cmi  OK.cmi OK.cmo MM.cmi MM.cmo VK.cmi VK.cmo

OK.cmi: SNTypes.cmi
OK.cmo: OK.cmi oauth/oauth.cma
OK.cmx: OK.cmi oauth/oauth.cmxa
MM.cmi: SNTypes.cmi
MM.cmo: MM.cmi oauth/oauth.cma
MM.cmx: MM.cmi oauth/oauth.cmxa
VK.cmi: SNTypes.cmi
VK.cmo: VK.cmi oauth/oauth.cma
VK.cmx: VK.cmi oauth/oauth.cmxa

.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o
	make -C oauth clean
	make -C facebook clean

