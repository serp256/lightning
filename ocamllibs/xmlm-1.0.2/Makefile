
OCAMLFIND=ocamlfind -toolchain ios
OCAMLOPT=$(OCAMLFIND) ocamlopt

all:
	$(OCAMLOPT) -c src/xmlm.mli
	$(OCAMLOPT) -c -annot -I src -I test -o src/xmlm.cmx src/xmlm.ml

install:
	$(OCAMLFIND) install xmlm src/META src/xmlm.mli src/xmlm.cmi src/xmlm.cmx src/xmlm.o src/xmlm.annot

uninstall:
	$(OCAMLFIND) remove xmlm
