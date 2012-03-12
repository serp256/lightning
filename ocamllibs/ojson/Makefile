
OCAMLFIND = ocamlfind -toolchain 313
OCAMLOPT=$(OCAMLFIND) ocamlopt
OCAMLC=$(OCAMLFIND) ocamlc


install: byte native
	$(OCAMLFIND) install ojson META ojson.cmi ojson.cma ojson.cmxa ojson.mli ojson.a

ios: OCAMLFIND = ocamlfind -toolchain ios
ios: install

byte:
	$(OCAMLC) -c type.ml
	$(OCAMLC) -c common.mli
	$(OCAMLC) -c common.ml
	$(OCAMLC) -c read.mli
	ocamllex -q read.mll
	$(OCAMLC) -c read.ml
	$(OCAMLC) -c ojson.mli
	$(OCAMLC) -c ojson.ml
	$(OCAMLC) -a type.cmo common.cmo read.cmo ojson.cmo -o ojson.cma

native:
	$(OCAMLOPT) -c type.ml
	$(OCAMLOPT) -c common.mli
	$(OCAMLOPT) -c common.ml
	$(OCAMLOPT) -c read.mli
	ocamllex -q read.mll
	$(OCAMLOPT) -c read.ml
	$(OCAMLOPT) -c ojson.mli
	$(OCAMLOPT) -c ojson.ml
	$(OCAMLOPT) -a type.cmx common.cmx read.cmx ojson.cmx -o ojson.cmxa


