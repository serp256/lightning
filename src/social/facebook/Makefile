include ../../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib 

MLSOURCES = FB.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

ifeq ($(PLATFORM),IOS)
CFLAGS  += -DDEBUG -DIOS -Fios/FacebookSDK -I../../ios -Iios/FacebookSDK/include
MOBJS   += ios/fbwrapper_ios.o
            
MLPPOPT += -DIOS
LIBFLAGS = -cclib '-framework\ Foundation' \
		   -cclib '-framework\ UIKit' \
		   -cclib '-framework\ QuartzCore' \
		   -cclib '-framework\ CoreGraphics' \
		   -cclib '-weak_framework\ Accounts' \
		   -cclib '-weak_framework\ Social' \
		   -cclib '-weak_framework\ AdSupport' \
		   -cclib '-framework\ FacebookSDK' \

#fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
#	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 
#
#fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS)
#	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS)

fb.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o fb $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fb.cma: $(IFACES) $(MOBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o fb $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

else
ifeq ($(PLATFORM),ANDROID)
CFLAGS += -DANDROID -I../../ -I../../android -I./android
MLPPOPT += -DANDROID
MOBJS += android/fbwrapper_android.o

fb.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o fb $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fb.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o fb $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

android/fbwrapper_android.o: CFLAGS += -DLDEBUG

else

MLPPOPT += -DPC

fb.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o fb.cmxa $(MLOBJSN)

fb.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o fb.cma $(MLOBJS)

endif
endif






.PHONY : clean
clean: 
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/sdk/*.o ios/*.o android/*.o

