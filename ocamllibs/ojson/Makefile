OCAMLFIND = ocamlfind

default: byte native

ios ios-install: OCAMLFIND = ocamlfind -toolchain ios
ios: native
ios-install: install

android android-install: OCAMLFIND = ocamlfind -toolchain android
android: native
android-install: install

include Makefile.in
