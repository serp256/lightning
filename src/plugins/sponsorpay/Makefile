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

CFLAGS  += -fobjc-arc -DIOS -Iios -Iios/sdk -Iios/include -I../../ios -I../.. -Fios
COBJS   += ios/sdk/NSString+SPURLEncoding.o ios/sdk/NSURL+SPParametersParsing.o ios/sdk/SPActionIdValidator.o ios/sdk/SPAdvertisementViewController.o ios/sdk/SPAdvertiserManager.o \
	ios/sdk/SPAppIdValidator.o ios/sdk/SPAppleAdvertiserIDProvider.o ios/sdk/SPBaseNetwork.o ios/sdk/SPBrandEngageClient.o ios/sdk/SPBrandEngageViewController.o \
	ios/sdk/SPBrandEngageWebView.o ios/sdk/SPBufferedLogger.o ios/sdk/SPCallbackSendingOperation.o ios/sdk/SPConstants.o ios/sdk/SPCredentials.o ios/sdk/SPCredentialsManager.o \
	ios/sdk/SPHostAppBundleParametersProvider.o ios/sdk/SPInterstitialClient.o ios/sdk/SPInterstitialEvent.o ios/sdk/SPInterstitialEventHub.o ios/sdk/SPInterstitialOffer.o \
	ios/sdk/SPInterstitialResponse.o ios/sdk/SPJailbreakStatusProvider.o ios/sdk/SPLoadingIndicator.o ios/sdk/SPLocaleParametersProvider.o ios/sdk/SPLogger.o \
	ios/sdk/SPMD5MacAddressProvider.o ios/sdk/SPMacAddressProvider.o ios/sdk/SPMediationCoordinator.o ios/sdk/SPNetworkOperation.o ios/sdk/SPNetworkParametersProvider.o \
	ios/sdk/SPOfferWallViewController.o ios/sdk/SPPersistence.o ios/sdk/SPRandomID.o ios/sdk/SPReachability.o ios/sdk/SPResourceLoader.o ios/sdk/SPSDKVersionProvider.o \
	ios/sdk/SPSHA1MacAddressProvider.o ios/sdk/SPSchemeParser.o ios/sdk/SPScreenMetricsProvider.o ios/sdk/SPSignature.o ios/sdk/SPSystemLogger.o ios/sdk/SPSystemParametersProvider.o \
	ios/sdk/SPSystemVersionChecker.o ios/sdk/SPTPNGenericAdapter.o ios/sdk/SPTPNManager.o ios/sdk/SPTPNMediationTypes.o ios/sdk/SPTargetedNotificationFilter.o ios/sdk/SPToast.o \
	ios/sdk/SPURLGenerator.o ios/sdk/SPVirtualCurrencyServerConnector.o ios/sdk/SponsorPaySDK.o \
	ios/adapters/Applifier/SPApplifierNetwork.o ios/adapters/Applifier/SPApplifierRewardedVideoAdapter.o \
	ios/adapters/AppLovin/SPAppLovinInterstitialAdapter.o ios/adapters/AppLovin/SPAppLovinNetwork.o ios/adapters/AppLovin/SPAppLovinRewardedVideoAdapter.o \
	ios/spwrapper_ios.o ios/VideoDelegate.o
LIBFLAGS += -cclib '-framework\ Foundation' -cclib '-framework\ ApplifierImpact' -cclib '-framework\ StoreKit' -cclib '-framework\ AdSupport' -cclib '-framework\ CoreMedia'

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
	rm -f *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/spwrapper_ios.o ios/sdk/*.o android/spwrapper_android.o

