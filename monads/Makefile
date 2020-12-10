
all: async_read_file.opt async_read_buffer.opt \
	rresult_read_file.opt rresult_read_buffer.opt \
	lwt_read_file.opt lwt_read_buffer.opt \
	direct_read_file.opt direct_read_buffer.opt

F=/dev/zero
N=10485760
test: all
	./async_read_buffer.opt $F $N
	./lwt_read_buffer.opt $F $N
	./rresult_read_buffer.opt $F $N
	./direct_read_buffer.opt $F $N
	./async_read_file.opt $F $N
	./lwt_read_file.opt $F $N
	./rresult_read_file.opt $F $N
	./direct_read_file.opt $F $N


async_read_file.opt: async_read_file.ml
	ocamlfind ocamlopt -thread -package async -linkall -linkpkg async_read_file.ml -o async_read_file.opt

async_read_buffer.opt: async_read_buffer.ml
	ocamlfind ocamlopt -thread -package async -linkall -linkpkg async_read_buffer.ml -o async_read_buffer.opt

rresult_read_file.opt: rresult_read_file.ml
	ocamlfind ocamlopt -thread -package rresult -linkall -linkpkg rresult_read_file.ml -o rresult_read_file.opt

rresult_read_buffer.opt: rresult_read_buffer.ml
	ocamlfind ocamlopt -thread -package rresult -linkall -linkpkg rresult_read_buffer.ml -o rresult_read_buffer.opt

lwt_read_file.opt: lwt_read_file.ml
	ocamlfind ocamlopt -thread -package lwt,lwt.unix -linkall -linkpkg lwt_read_file.ml -o lwt_read_file.opt

lwt_read_buffer.opt: lwt_read_buffer.ml
	ocamlfind ocamlopt -thread -package lwt,lwt.unix -linkall -linkpkg lwt_read_buffer.ml -o lwt_read_buffer.opt

direct_read_file.opt: direct_read_file.ml
	ocamlfind ocamlopt -thread -package unix -linkall -linkpkg direct_read_file.ml -o direct_read_file.opt

direct_read_buffer.opt: direct_read_buffer.ml
	ocamlfind ocamlopt -thread -package unix -linkall -linkpkg direct_read_buffer.ml -o direct_read_buffer.opt

clean::
	rm -f *.cm* *.o *.opt *.byte
