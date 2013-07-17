include ../../../Makefile.common

CFLAGS += -I . 
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = Twitter.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS -Iios -I../../ios
COBJS   +=  ios/twitter_ios.o
            
LIBFLAGS = -cclib '-framework\ Accounts' \
			-cclib '-framework\ Social' \
			-cclib '-framework\ Twitter'

else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/twitter_android.o


endif
endif


ifeq ($(PLATFORM),PC)
	
twitter.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o twitter.cmxa $(MLOBJSN)

twitter.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o twitter.cma $(MLOBJS)

else
twitter.cmxa: $(IFACES) $(COBJS) $(MLOBJSN) 
	$(OCAMLMKLIB) -verbose -o twitter $(COBJS) $(MLOBJSN) $(LIBFLAGS)

twitter.cma: $(IFACES) $(COBJS) $(MLOBJS) 
	$(OCAMLMKLIB) -verbose -o twitter $(COBJS) $(MLOBJS) $(LIBFLAGS) 
endif


.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/twitter_wrapper.o android/twitter_wrapper.o

