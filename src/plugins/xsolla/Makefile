include ../../../Makefile.common

CFLAGS += -I . 
 CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Xsolla.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ -I../../ios -I../common
COBJS   +=  ios/xsolla_ios.o

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common -Iandroid/sdk
COBJS   +=  android/xsolla_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
xsolla.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o xsolla.cmxa $(MLOBJSN)

xsolla.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o xsolla.cma $(MLOBJS)

else
xsolla.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o xsolla $(COBJS) $(MLOBJSN) $(LIBFLAGS)

xsolla.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o xsolla $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/xsolla_ios.o android/xsolla_android.o
