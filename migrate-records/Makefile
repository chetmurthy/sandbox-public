NOT_OCAMLFIND=not-ocamlfind
OCAMLFIND=ocamlfind
PACKAGES=camlp5
PRPACKAGE = camlp5.pr_o
SYNTAX = camlp5o
IMPORT_CFLAGS=-ppopt -pa_import-I -ppopt .
DEBUG=-g

all: rec_migrate.cmo

rec_types.cmo: rec_types.ml
	$(NOT_OCAMLFIND) preprocess $(OCAMLCFLAGS) -package $(PACKAGES),$(PRPACKAGE),pa_ppx.import,pa_ppx_migrate $(IMPORT_CFLAGS) -syntax $(SYNTAX) $< > $*_ppo.ml
	$(OCAMLFIND) ocamlc $(DEBUG) $(WARNERR) $(OCAMLCFLAGS) -package $(PACKAGES),pa_ppx.import,pa_ppx_migrate $(IMPORT_CFLAGS) -syntax camlp5o -c $<

rec_migrate.cmo: rec_migrate.ml rec_types.cmi
	$(NOT_OCAMLFIND) preprocess $(OCAMLCFLAGS) -package $(PACKAGES),$(PRPACKAGE),pa_ppx.import,pa_ppx_migrate $(IMPORT_CFLAGS) -syntax $(SYNTAX) $< > $*_ppo.ml
	$(OCAMLFIND) ocamlc $(DEBUG) $(WARNERR) $(OCAMLCFLAGS) -package $(PACKAGES),pa_ppx.import,pa_ppx_migrate $(IMPORT_CFLAGS) -syntax camlp5o -c $<

.SUFFIXES: .cmo .cmi .mll .ml .mli .cmx .cma .cmxa .cmt .cmti

rec_types.cmo: rec_types.ml
rec_types.cmi: rec_types.ml

clean::
	$(RM) -rf *.cm* *.o *.a *.byte *.opt *.log *.cache *.ppo *ppo.ml _build/* .cmt *.odoc .depend.NEW

realclean:: clean
