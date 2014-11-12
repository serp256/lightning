include ../../../Makefile.common

CFLAGS += -I .
CFLAGS += -DLDEBUG -g

MLFLAGS += -package redspell.syntax.debug

%.o: %.c
	$(OCAMLOPT) -I . -verbose -g  $(if $(CFLAGS),$(patsubst %,-ccopt %,$(CFLAGS))) -ccopt '-fPIC' -ccopt '-o $@' -c $<

MLSOURCES = NativeVk.ml
MLOBJSN = $(MLSOURCES:.ml=.cmx)
MLOBJS = $(MLSOURCES:.ml=.cmo)
IFACES = $(MLSOURCES:.ml=.cmi)

MLFLAGS += -I ..

MLPPOPT += ../../syntax/pa_platform.cmo -enable-debug default

ifeq ($(PLATFORM),IOS)

MLPPOPT += -DIOS

CFLAGS  += -fmodules -fobjc-arc -DIOS -Iios -I../../ -I../../ios -I../common -I ios/sdk/sdk/sdk -I ios/sdk/sdk/sdk/models -I ios/sdk/sdk/sdk/ShareDialog
COBJS   +=  ios/vk_ios.o ios/LightVkDelegate.o ios/sdk/sdk/sdk/models/VKApiObject.o ios/sdk/sdk/sdk/models/VKApiObjectArray.o ios/sdk/sdk/sdk/models/VKAudio.o ios/sdk/sdk/sdk/models/VKCounters.o \
	ios/sdk/sdk/sdk/models/VKGroup.o ios/sdk/sdk/sdk/models/VKLikes.o ios/sdk/sdk/sdk/models/VKPhoto.o ios/sdk/sdk/sdk/models/VKPhotoSize.o \
	ios/sdk/sdk/sdk/models/VKRelative.o ios/sdk/sdk/sdk/models/VKSchool.o ios/sdk/sdk/sdk/models/VKUniversity.o ios/sdk/sdk/sdk/models/VKUser.o \
	ios/sdk/sdk/sdk/NSData+MD5.o ios/sdk/sdk/sdk/NSError+VKError.o ios/sdk/sdk/sdk/NSString+MD5.o ios/sdk/sdk/sdk/OrderedDictionary.o \
	ios/sdk/sdk/sdk/ShareDialog/VKShareDialogController.o ios/sdk/sdk/sdk/VKAccessToken.o ios/sdk/sdk/sdk/VKApi.o ios/sdk/sdk/sdk/VKApiBase.o \
	ios/sdk/sdk/sdk/VKApiCaptcha.o ios/sdk/sdk/sdk/VKApiFriends.o ios/sdk/sdk/sdk/VKApiGroups.o ios/sdk/sdk/sdk/VKApiPhotos.o ios/sdk/sdk/sdk/VKApiUsers.o \
	ios/sdk/sdk/sdk/VKApiWall.o ios/sdk/sdk/sdk/VKAuthorizeController.o ios/sdk/sdk/sdk/VKBatchRequest.o ios/sdk/sdk/sdk/VKBundle.o \
	ios/sdk/sdk/sdk/VKCaptchaView.o ios/sdk/sdk/sdk/VKCaptchaViewController.o ios/sdk/sdk/sdk/VKError.o ios/sdk/sdk/sdk/VKHTTPClient.o \
	ios/sdk/sdk/sdk/VKHTTPOperation.o ios/sdk/sdk/sdk/VKImageParameters.o ios/sdk/sdk/sdk/VKObject.o ios/sdk/sdk/sdk/VKOperation.o \
	ios/sdk/sdk/sdk/VKPermissions.o ios/sdk/sdk/sdk/VKRequest.o ios/sdk/sdk/sdk/VKResponse.o ios/sdk/sdk/sdk/VKSdk.o ios/sdk/sdk/sdk/VKUploadImage.o \
	ios/sdk/sdk/sdk/VKUploadMessagesPhotoRequest.o ios/sdk/sdk/sdk/VKUploadPhotoBase.o ios/sdk/sdk/sdk/VKUploadPhotoRequest.o \
	ios/sdk/sdk/sdk/VKUploadWallPhotoRequest.o ios/sdk/sdk/sdk/VKUtil.o

else
ifeq ($(PLATFORM),ANDROID)

MLPPOPT += -DANDROID

CFLAGS  += -DANDROID -Iandroid -I../../ -I../../android -I../common
COBJS   +=  android/vk_android.o


endif
endif


ifeq ($(PLATFORM),PC)

MLPPOPT += -DPC

NativeVk.cmxa: $(IFACES) $(MLOBJSN)
	$(OCAMLOPT) -a -o NativeVk.cmxa $(MLOBJSN)

NativeVk.cma: $(IFACES) $(MLOBJS)
	$(OCAMLC) -a -o NativeVk.cma $(MLOBJS)

else
NativeVk.cmxa: $(IFACES) $(COBJS) $(MLOBJSN)
	$(OCAMLMKLIB) -verbose -o NativeVk $(COBJS) $(MLOBJSN) $(LIBFLAGS)

NativeVk.cma: $(IFACES) $(COBJS) $(MLOBJS)
	$(OCAMLMKLIB) -verbose -o NativeVk $(COBJS) $(MLOBJS) $(LIBFLAGS)
endif


.PHONY : clean
clean:
	rm -f ios/sdk/sdk/sdk/*.o *.o *.cm[ioxa] *.a *.cmxa *.so *.cmo ios/*.o android/vk_android.o
