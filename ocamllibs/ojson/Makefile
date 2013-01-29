
OCAMLFIND = ocamlfind

default: byte native

ios ios-install ios-uninstall: OCAMLFIND = ocamlfind -toolchain ios
ios: native
ios-install: install
ios-uninstall: uninstall

android android-install android-uninstall: OCAMLFIND = ocamlfind -toolchain android
android: native
android-install: install
android-uninstall: uninstall


OCAMLOPT=$(OCAMLFIND) ocamlopt
OCAMLC=$(OCAMLFIND) ocamlc


install: byte native
	$(OCAMLFIND) install ojson META ojson.cmi ojson.cma ojson.cmxa ojson.mli ojson.a

uninstall:
	$(OCAMLFIND) remove ojson

byte:
	$(OCAMLC) -c bi_outbuf.mli
	$(OCAMLC) -c bi_outbuf.ml
	$(OCAMLC) -c type.ml
	$(OCAMLC) -c common.mli
	$(OCAMLC) -c common.ml
	$(OCAMLC) -c read.mli
	ocamllex -q read.mll
	$(OCAMLC) -c read.ml
	$(OCAMLC) -c write.mli
	$(OCAMLC) -c write.ml
	$(OCAMLC) -c ojson.mli
	$(OCAMLC) -c ojson.ml
	$(OCAMLC) -a bi_outbuf.cmo type.cmo common.cmo read.cmo write.cmo ojson.cmo -o ojson.cma

native:
	$(OCAMLOPT) -c bi_outbuf.mli
	$(OCAMLOPT) -c bi_outbuf.ml
	$(OCAMLOPT) -c type.ml
	$(OCAMLOPT) -c common.mli
	$(OCAMLOPT) -c common.ml
	$(OCAMLOPT) -c read.mli
	ocamllex -q read.mll
	$(OCAMLOPT) -c read.ml
	$(OCAMLOPT) -c write.mli
	$(OCAMLOPT) -c write.ml
	$(OCAMLOPT) -c ojson.mli
	$(OCAMLOPT) -c ojson.ml
	$(OCAMLOPT) -a bi_outbuf.cmx type.cmx common.cmx read.cmx write.cmx ojson.cmx -o ojson.cmxa


clean:
	rm -f *.cmo *.cmx *.cmxa *.a *.o *.cmi *.cma read.ml
