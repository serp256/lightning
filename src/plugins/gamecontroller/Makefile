include ../../../Makefile.common

CFLAGS += -I .
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Gamecontroller.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ -I../../ios -I../common
COBJS   +=  ios/gamecontroller_ios.o

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/gamecontroller_android.o


endif
endif


ifeq ($(PLATFORM),PC)

gamecontroller.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o gamecontroller.cmxa $(MLOBJSN)

gamecontroller.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o gamecontroller.cma $(MLOBJS)

else
gamecontroller.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o gamecontroller $(COBJS) $(MLOBJSN) $(LIBFLAGS)

gamecontroller.cma: $(IFACES) $(COBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o gamecontroller $(COBJS) $(MLOBJS) $(LIBFLAGS)
endif


.PHONY : clean
clean:
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/gamecontroller_ios.o android/gamecontroller_android.o
