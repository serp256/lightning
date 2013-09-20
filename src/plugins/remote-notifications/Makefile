include ../../../Makefile.common

CFLAGS += -I . 
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = RemoteNotifications.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ -I../../ios -I../common
COBJS   +=  ios/rn_ios.o

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/rn_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
remote-notifications.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o RemoteNotifications.cmxa $(MLOBJSN)

remote-notifications.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o RemoteNotifications.cma $(MLOBJS)

else
remote-notifications.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o remote-notifications $(COBJS) $(MLOBJSN) $(LIBFLAGS)

remote-notifications.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o remote-notifications $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/rn_ios.o android/rn_android.o
