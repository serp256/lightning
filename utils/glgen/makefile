
TARGET =


es: TARGET = es
sdl: TARGET = sdl

es: all
sdl: all

all: glgen
	mkdir -p output/$(TARGET)
	cp data/$(TARGET)_header.c data/header.c
	./glgen data/$(TARGET).txt
	ocamlc -i output/glcaml.ml > output/glcaml.tmp.mli
	cat data/mliheader.ml output/glcaml.tmp.mli > output/glcaml.mli
	rm output/glcaml.tmp.mli
	camlp4o output/glcaml.ml -printer r > output/$(TARGET)/gl.ml
	camlp4o output/glcaml.mli -printer r > output/$(TARGET)/gl.mli
	mv output/gl_stub.c output/$(TARGET)/
	rm output/glcaml.ml{,i}
	
glgen: data.mli data.ml glparse.mly glparse.mli gllex.mll gllex.ml
	ocamlc -c data.mli -g
	ocamlc -c data.ml -g
	ocamlyacc glparse.mly
	ocamlc -c glparse.mli -g
	ocamlc -c glparse.ml -g
	ocamllex gllex.mll
	ocamlc -c gllex.ml -g
	ocamlc data.mli data.ml glparse.mli glparse.ml gllex.ml main.ml -o glgen -g

clean:
	rm -f *.o *.cmi *.cmo glparse.mli glparse.ml gllex.ml glgen output/*	
