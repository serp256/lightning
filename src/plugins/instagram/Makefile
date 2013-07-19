include ../../../Makefile.common

CFLAGS += -I . 
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Instagram.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ios
COBJS   +=  ios/instagram_ios.o

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/instagram_android.o

endif
endif


ifeq ($(PLATFORM),PC)
	
instagram.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o instagram.cmxa $(MLOBJSN)

instagram.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o instagram.cma $(MLOBJS)

else
instagram.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o instagram $(COBJS) $(MLOBJSN) $(LIBFLAGS)

instagram.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o instagram $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/instagram_ios.o android/instagram_android.o

