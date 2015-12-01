include ../../../Makefile.common

CFLAGS += -I . 
#CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Gameanalytics.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ -I../../ios -I../common -Iios/sdk
COBJS   +=  ios/gameanalytics_ios.o

LIBFLAGS = -cclib '-weak_framework\ AdSupport' \
		   -cclib '-framework\ SystemConfiguration' \
		   -cclib '-lsqlite3' \
		   -cclib '-lz' \
			 -lGameAnalyticsSDK

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common -Iandroid/sdk
COBJS   +=  android/gameanalytics_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
gameanalytics.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o gameanalytics.cmxa $(MLOBJSN)

gameanalytics.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o gameanalytics.cma $(MLOBJS)

else
gameanalytics.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o gameanalytics $(COBJS) $(MLOBJSN) $(LIBFLAGS)

gameanalytics.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o gameanalytics $(COBJS) $(MLOBJS) $(LIBFLAGS) 

endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/gameanalytics_ios.o android/gameanalytics_android.o
