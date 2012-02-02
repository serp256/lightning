
MLPPOPT = $(LIGHTNING_PATH)/syntax/pa_prop.cmo $(LIGHTNING_PATH)/syntax/pa_debug.cmo -enable-debug default

example:
	ocamlfind ocamlc -verbose -o example -syntax camlp4r -g \
		-I ../src/lightning.cma \
		 -package camlp4,extlib  -linkpkg example.ml
