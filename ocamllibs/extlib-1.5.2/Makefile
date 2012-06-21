default: OCAMLFIND=ocamlfind
default: all

ios ios-install: OCAMLFIND=ocamlfind -toolchain ios
ios: all
ios-install: install

android: OCAMLFIND=ocamlfind -toolchain android
android: all

include Makefile.in
