default: OCAMLFIND=ocamlfind
default: all

ios ios-install: OCAMLFIND=ocamlfind -toolchain ios
ios: all
ios-install: install

android android-install: OCAMLFIND=ocamlfind -toolchain android
android: all
android-install: install

include Makefile.in
