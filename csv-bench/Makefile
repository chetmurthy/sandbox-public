
caml1.opt: caml1.ml
	ocamlfind ocamlopt -O3 -package pa_ppx_regexp,fmt -linkpkg -linkall -syntax camlp5o caml1.ml -o caml1.opt

caml1: caml1.ml
	ocamlfind ocamlc -package pa_ppx_regexp,fmt -linkpkg -linkall -syntax camlp5o caml1.ml -o caml1

caml2.opt: caml2.ml
	ocamlfind ocamlopt -O3 -package pa_ppx_regexp,fmt -linkpkg -linkall -syntax camlp5o caml2.ml -o caml2.opt

caml2: caml2.ml
	ocamlfind ocamlc -package pa_ppx_regexp,fmt -linkpkg -linkall -syntax camlp5o caml2.ml -o caml2

clean:
	rm -f *.cm* caml1 caml2 *.opt

bench:: caml1 caml2 caml1.opt caml2.opt
	@echo "==== py1 ===="
	python py1.py -w 100 -c 10 -d 10 CAJAL/CAJAL/data/swc/320668879.swc
	@echo "==== caml1 ===="
	./caml1 -warmup 100 -count 10 -dump 10 CAJAL/CAJAL/data/swc/320668879.swc
	@echo "==== caml1.opt ===="
	./caml1.opt -warmup 100 -count 10 -dump 10 CAJAL/CAJAL/data/swc/320668879.swc
	@echo "==== py2 ===="
	python py2.py -w 100 -c 1000000 -d
	@echo "==== caml2 ===="
	./caml2 -warmup 100 -count 1000000 -dump
	@echo "==== caml2.opt ===="
	./caml2.opt -warmup 100 -count 1000000 -dump
	@echo "==== py2 count=37950 ===="
	python py2.py -w 100 -c  37950 -d
	@echo "==== caml2 count=37950 ===="
	./caml2 -warmup 100 -count 37950 -dump
