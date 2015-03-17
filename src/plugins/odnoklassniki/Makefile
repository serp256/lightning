include ../../../Makefile.common

CFLAGS += -I . 
# CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Odnoklassniki.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -fobjc-arc -Iios -I../../ -I../../ios -I../common -I ios/sdk/OKSdk/OKSdk -I ios/sdk/OKSdk/OKSdk/Friends -I ios/sdk/OKSdk/OKSdk/Utils -I ios/sdk/OKSdk/OKSdk/UI
COBJS   +=  ios/odnoklassniki_ios.o ios/LightOkDelegate.o ios/odnoklassniki_ios.o ios/sdk/OKSdk/OKSdk/Friends/OKFriends.o ios/sdk/OKSdk/OKSdk/Odnoklassniki.o ios/sdk/OKSdk/OKSdk/OKRequest.o ios/sdk/OKSdk/OKSdk/OKSession.o ios/sdk/OKSdk/OKSdk/OKTokenCache.o ios/sdk/OKSdk/OKSdk/UI/OKAuthorizeController.o ios/sdk/OKSdk/OKSdk/UI/OKMediaTopicPostViewController.o ios/sdk/OKSdk/OKSdk/Utils/NSString+OKUtils.o

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/odnoklassniki_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
odnoklassniki.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o odnoklassniki.cmxa $(MLOBJSN)

odnoklassniki.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o odnoklassniki.cma $(MLOBJS)

else
odnoklassniki.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o odnoklassniki $(COBJS) $(MLOBJSN) $(LIBFLAGS)

odnoklassniki.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o odnoklassniki $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o android/odnoklassniki_android.o ios/sdk/OKSdk/OKSdk/*.o ios/sdk/OKSdk/OKSdk/*/*.o
