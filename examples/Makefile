


all:
	ocamlfind ocamlopt -verbose -o example -syntax camlp4r -g \
		-I ../src ../src/lightning.cmxa \
		 -package camlp4,bigarray,extlib,xmlm -linkpkg example.ml
