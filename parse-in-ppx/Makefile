
DEBUG=
PACKAGES=bos,fmt,camlp5,pcre,pa_ppx.base,camlp5.quotations,camlp5.extfun

all: toy.cmo pa_fsm.cmo fsm_test

fsm_test: fsm_test.ml toy.cmo pa_fsm.cmo
	not-ocamlfind preprocess -package $(PACKAGES),camlp5.pr_o \
	-ppopt -I -ppopt . -ppopt toy.cmo -ppopt pa_fsm.cmo -syntax camlp5o \
	fsm_test.ml > fsm_test.ppo
	ocamlfind ocamlc -package $(PACKAGES) \
	-ppopt -I -ppopt . -ppopt toy.cmo -ppopt pa_fsm.cmo -syntax camlp5o \
	toy.cmo fsm_test.ml -o fsm_test

.ml.cmo:
	not-ocamlfind preprocess -package $(PACKAGES),camlp5.pr_r -syntax camlp5o $< > $<.ppo
	ocamlfind ocamlc $(DEBUG) -package $(PACKAGES) -syntax camlp5o -c $<

.ml.cmx:
	ocamlfind ocamlopt $(DEBUG) -package $(PACKAGES) -syntax camlp5o -c $<

.SUFFIXES: .ml .cmo .cmi .cmx

clean::
	rm -f *.cm* *.ppo *.o

pa_fsm.cmo: toy.cmi
pa_fsm.cmx: toy.cmi
