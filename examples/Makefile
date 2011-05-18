


all:
	ocamlfind ocamlopt -verbose -o example -syntax camlp4r -g \
		-I ../_build/src ../_build/src/lightning.cmxa \
		 -package camlp4,bigarray,extlib,xmlm -linkpkg example.ml
