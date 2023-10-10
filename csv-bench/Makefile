
caml1: caml1.ml
	ocamlfind ocamlc -package pa_ppx_regexp,fmt -linkpkg -linkall -syntax camlp5o caml1.ml -o caml1

clean:
	rm -f *.cm* caml1

bench:: caml1
	@echo "==== python ===="
	python py1.py -w 100 -c 10 -d 10 CAJAL/CAJAL/data/swc/320668879.swc
	@echo "==== caml1 ===="
	./caml1 -warmup 100 -count 10 -dump 10 CAJAL/CAJAL/data/swc/320668879.swc
