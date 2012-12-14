include ../../../Makefile.common

CFLAGS += -I . 

MLFLAGS += -package ojson,extlib 


MLSOURCES = FB.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

ifeq ($(PLATFORM),IOS)
CFLAGS  += -DDEBUG -DIOS -Fios/FacebookSDK -I../../ios -Iios/FacebookSDK/include
MOBJS   += ios/fbwrapper_ios.o ios/FacebookController.o
#MOBJS 	+= ios/FacebookSDK/src/FBCacheDescriptor.o ios/FacebookSDK/src/FBCacheIndex.o ios/FacebookSDK/src/FBContentLink.o \
#	ios/FacebookSDK/src/FBDataDiskCache.o ios/FacebookSDK/src/FBDialog.o ios/FacebookSDK/src/FBError.o \
#	ios/FacebookSDK/src/FBFrictionlessRequestSettings.o ios/FacebookSDK/src/FBFriendPickerCacheDescriptor.o \
#	ios/FacebookSDK/src/FBFriendPickerViewController.o ios/FacebookSDK/src/FBGraphObject.o \
#	ios/FacebookSDK/src/FBGraphObjectPagingLoader.o ios/FacebookSDK/src/FBGraphObjectTableCell.o \
#	ios/FacebookSDK/src/FBGraphObjectTableDataSource.o ios/FacebookSDK/src/FBGraphObjectTableSelection.o \
#	ios/FacebookSDK/src/FBLogger.o ios/FacebookSDK/src/FBLoginDialog.o ios/FacebookSDK/src/FBLoginView.o \
#	ios/FacebookSDK/src/FBNativeDialogs.o ios/FacebookSDK/src/FBPlacePickerCacheDescriptor.o \
#	ios/FacebookSDK/src/FBPlacePickerViewController.o ios/FacebookSDK/src/FBProfilePictureView.o \
#	ios/FacebookSDK/src/FBRequest.o ios/FacebookSDK/src/FBRequestBody.o ios/FacebookSDK/src/FBRequestConnection.o \
#	ios/FacebookSDK/src/FBSession.o ios/FacebookSDK/src/FBSessionManualTokenCachingStrategy.o \
#	ios/FacebookSDK/src/FBSessionTokenCachingStrategy.o ios/FacebookSDK/src/FBSettings.o ios/FacebookSDK/src/FBTestSession.o \
#	ios/FacebookSDK/src/FBURLConnection.o ios/FacebookSDK/src/FBUserSettingsViewController.o ios/FacebookSDK/src/FBUtility.o \
#	ios/FacebookSDK/src/FBViewController.o ios/FacebookSDK/src/Facebook.o
#MOBJS 	+= ios/FacebookSDK/src/JSON/FBSBJSON.o ios/FacebookSDK/src/JSON/FBSBJsonBase.o ios/FacebookSDK/src/JSON/FBSBJsonParser.o \
#	ios/FacebookSDK/src/JSON/FBSBJsonWriter.o
            
MLPPOPT += -DGLES -DIOS
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
CFLAGS = -DANDROID -I../../ -I../android
MLPPOPT += -DGLES -DANDROID
MOBJS += android/fbwrapper_android.o

fbconnect.cmxa: $(IFACES) $(MOBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJSN) $(LIBFLAGS) 

fbconnect.cma: $(IFACES) $(MOBJS) $(MLOBJS) $(FAKELIBS)
	$(OCAMLMKLIB) -verbose -o fbconnect $(MOBJS) $(MLOBJS) $(LIBFLAGS) 

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

