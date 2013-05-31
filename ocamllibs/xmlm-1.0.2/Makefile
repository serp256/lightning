OCAMLFIND = ocamlfind
default: all

ios ios-install ios-uninstall: OCAMLFIND = ocamlfind -toolchain ios
ios: all
ios-install: install
ios-uninstall: uninstall

android android-install android-uninstall: OCAMLFIND = ocamlfind -toolchain android
android: all
android-install: install
android-uninstall: uninstall

include Makefile.in
