OCAMLFIND=ocamlfind

default: all

ios ios-install ios-uninstall: OCAMLFIND=ocamlfind -toolchain ios 
ios: all
ios-install: install
ios-uninstall: uninstall

ios64 ios64-install ios64-uninstall: OCAMLFIND=ocamlfind -toolchain ios64 
ios64: all
ios64-install: install
ios64-uninstall: uninstall

android android-install android-uninstall: OCAMLFIND=ocamlfind -toolchain android
android: all
android-install: install
android-uninstall: uninstall

include Makefile.in
