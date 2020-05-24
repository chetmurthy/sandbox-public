
EXE=calc

all: $(EXE)

calc: calc.ml
	ocamlfind ocamlc $(DEBUG) -package camlp5,sexplib -syntax camlp5r -linkall -linkpkg calc.ml -o calc

clean::
	rm -f *.cm* $(EXE)
