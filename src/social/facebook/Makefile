include ../../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib 

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = FBConnect.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

ifeq ($(PLATFORM),IOS)
FAKELIBS  =
CFLAGS  += -DDEBUG -DIOS -Iios/sdk
MLCOPTS += -DIOS
MOBJS   +=  ios/fbwrapper_ios.o ios/FacebookController.o ios/FacebookDialogDelegate.o ios/FacebookRequestDelegate.o ios/sdk/Facebook.o \
            ios/sdk/FBRequest.o ios/sdk/FBDialog.o ios/sdk/FBLoginDialog.o \
            ios/sdk/SBJSON.o ios/sdk/SBJsonBase.o ios/sdk/SBJsonParser.o ios/sdk/SBJsonWriter.o \
            ios/sdk/NSObject+SBJSON.o ios/sdk/NSString+SBJSON.o
            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' 

fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else
ifeq ($(PLATFORM),ANDROID)
FAKELIBS  =
MLCOPTS += -DANDROID
MLPPOPT += -DGLES -DANDROID

#fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN) $(FAKELIBS)
#`	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

#fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
#	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

fbconnect.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o fbconnect.cmxa $(MLOBJSN)

fbconnect.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o fbconnect.cma $(MLOBJS)

else

fbconnect.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o fbconnect.cmxa $(MLOBJSN)

fbconnect.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o fbconnect.cma $(MLOBJS)

endif
endif






.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o

