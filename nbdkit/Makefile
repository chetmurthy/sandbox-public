
DEBUG=

all: d2d d2d.opt d2d.cmo

d2d: d2d.cmo d2d_main.cmo
	ocamlfind ocamlc $(DEBUG) -package fmt,camlp5.fstream -syntax camlp5r -linkpkg $^ -o $@

d2d.opt: d2d.cmx d2d_main.cmx
	ocamlfind ocamlopt $(DEBUG) -package fmt,camlp5.fstream -syntax camlp5r -linkpkg $^ -o $@

.ml.cmo:
	not-ocamlfind preprocess -package fmt,camlp5.fstream,camlp5.pr_r -syntax camlp5r $< > $<.ppo
	ocamlfind ocamlc $(DEBUG) -package fmt,camlp5.fstream -syntax camlp5r -c $<

.ml.cmx:
	ocamlfind ocamlopt $(DEBUG) -package fmt,camlp5.fstream -syntax camlp5r -c $<

.SUFFIXES: .ml .cmo .cmi .cmx

clean::
	rm -f *.cm* *.ppo d2d d2d.opt *.o

d2d_main.cmo: d2d.cmo

