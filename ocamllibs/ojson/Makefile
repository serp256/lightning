OCAMLFIND = ocamlfind

default: byte native

ios ios-install ios-uninstall: OCAMLFIND = ocamlfind -toolchain ios
ios: native
ios-install: install
ios-uninstall: uninstall

android android-install: OCAMLFIND = ocamlfind -toolchain android
android: native
android-install: install

include Makefile.in
