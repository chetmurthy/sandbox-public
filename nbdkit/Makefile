
DEBUG=
PACKAGES=bos,fmt,camlp5.fstream,pcre

all: d2d d2d.opt d2d2 d2d2.opt d2d.cmo d2d2.cmo

d2d: d2d_shared.cmo d2d.cmo d2d_main.cmo
	ocamlfind ocamlc $(DEBUG) -package $(PACKAGES) -syntax camlp5r -linkpkg $^ -o $@

d2d.opt: d2d_shared.cmx d2d.cmx d2d_main.cmx
	ocamlfind ocamlopt $(DEBUG) -package $(PACKAGES) -syntax camlp5r -linkpkg $^ -o $@

d2d2: d2d_shared.cmo d2d2.cmo d2d2_main.cmo
	ocamlfind ocamlc $(DEBUG) -package $(PACKAGES) -syntax camlp5r -linkpkg $^ -o $@

d2d2.opt: d2d_shared.cmx d2d2.cmx d2d2_main.cmx
	ocamlfind ocamlopt $(DEBUG) -package $(PACKAGES) -syntax camlp5r -linkpkg $^ -o $@

.ml.cmo:
	not-ocamlfind preprocess -package $(PACKAGES),camlp5.pr_r -syntax camlp5r $< > $<.ppo
	ocamlfind ocamlc $(DEBUG) -package $(PACKAGES) -syntax camlp5r -c $<

.ml.cmx:
	ocamlfind ocamlopt $(DEBUG) -package $(PACKAGES) -syntax camlp5r -c $<

.SUFFIXES: .ml .cmo .cmi .cmx

clean::
	rm -f *.cm* *.ppo d2d d2d.opt d2d2 d2d2.opt *.o

d2d_main.cmo: d2d.cmo
d2d.cmo: d2d_shared.cmo
d2d2.cmo: d2d_shared.cmo

