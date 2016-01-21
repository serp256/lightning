include ../../../Makefile.common

CFLAGS += -I . 
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = QQ.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ -I../../ios -I../common -Iios/TencentOAuth.framework/Headers
COBJS   +=  ios/qq_ios.o ios/LightQQDelegate.o
MLPPOPT += -DIOS
LIBFLAGS = -cclib '-framework\ TencentOAuth'\
					 -cclib '-framework\ CoreTelephony' \
					-cclib '-lstdc++'\
					-cclib '-lz'

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/qq_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
qq.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o qq.cmxa $(MLOBJSN)

qq.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o qq.cma $(MLOBJS)

else
qq.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o qq $(COBJS) $(MLOBJSN) $(LIBFLAGS)

qq.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o qq $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/qq_ios.o android/qq_android.o
