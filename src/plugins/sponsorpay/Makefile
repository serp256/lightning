include ../../../Makefile.common

CFLAGS += -I .
CFLAGS += -DLDEBUG

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = SponsorPay.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

CFLAGS  += -DIOS \
	-fobjc-arc \
	-I../.. -I../../ios -Iios -Iios/sdk -Iios/include -Iios/adapters -Iios/adapters/applifier
COBJS += ios/spwrapper_ios.o ios/VideoDelegate.o

LIBFLAGS +=  -lSponsorPaySDK \
  -framework Fyber_UnityAds_1.4.5_r1 \
  -framework Foundation \
	-framework StoreKit \
	-framework AdSupport \
	-framework MediaPlayer \
	-framework CoreMedia \
	-framework CoreGraphics \
	-framework CoreLocation \
	-framework CFNetwork \
	-framework CoreTelephony \
	-framework QuartzCore \
	-framework AVFoundation \
	-framework SystemConfiguration
	
else
ifeq ($(PLATFORM),ANDROID)

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I ../common
COBJS   +=  android/spwrapper_android.o


endif
endif


ifeq ($(PLATFORM),PC)

sponsorpay.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o $@  $(MLOBJSN)

sponsorpay.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o $@ $(MLOBJS)

else
sponsorpay.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o sponsorpay $(COBJS) $(MLOBJSN) $(LIBFLAGS)

sponsorpay.cma: $(IFACES) $(COBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o sponsorpay $(COBJS) $(MLOBJS) $(LIBFLAGS)
endif


.PHONY : clean
clean:
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/spwrapper_ios.o ios/VideoDelegate.o ios/sdk/*.o ios/adapters/*/*.o android/spwrapper_android.o
