include ../../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib 


MLSOURCES = FBConnect.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

ifeq ($(PLATFORM),IOS)
CFLAGS  += -DDEBUG -DIOS -Iios/sdk
MOBJS   +=  ios/fbwrapper_ios.o ios/FacebookController.o ios/FacebookDialogDelegate.o ios/FacebookRequestDelegate.o ios/sdk/FBFrictionlessRequestSettings.o ios/sdk/Facebook.o \
            ios/sdk/FBRequest.o ios/sdk/FBDialog.o ios/sdk/FBLoginDialog.o \
            ios/sdk/JSON/SBJSON.o ios/sdk/JSON/SBJsonBase.o ios/sdk/JSON/SBJsonParser.o ios/sdk/JSON/SBJsonWriter.o \
            ios/sdk/JSON/NSObject+SBJSON.o ios/sdk/JSON/NSString+SBJSON.o

ios/fbwrapper_ios.o ios/FacebookController.o ios/FacebookDialogDelegate.o ios/FacebookRequestDelegate.o ios/sdk/Facebook.o ios/sdk/FBRequest.o ios/sdk/FBDialog.o: CFLAGS += -I ios/sdk/JSON
            
MLPPOPT += -DGLES -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' 

fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else
ifeq ($(PLATFORM),ANDROID)
CFLAGS = -DANDROID -I../../ -I../android
MLPPOPT += -DGLES -DANDROID
MOBJS += android/fbwrapper_android.o

fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

android/fbwrapper_android.o: CFLAGS += -DLDEBUG

else

fbconnect.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o fbconnect.cmxa $(MLOBJSN)

fbconnect.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o fbconnect.cma $(MLOBJS)

endif
endif






.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o android/*.o

