type neuron_node = {
    sample_number: int
  ; structure_id: int
  ; coord_triple: float * float * float
  ; radius: float
  ; parent_sample_number: int
  }

let dump_node nn =
  let (coord1, coord2, coord3) = nn.coord_triple in
  Fmt.(str "NeuronNode(sample_number=%d, structure_id=%d, coord_triple=(%f, %f, %f), radius=%f, parent_sample_number=%d)"
       nn.sample_number
       nn.structure_id
       coord1
       coord2
       coord3
       nn.radius
       nn.parent_sample_number)

let strip s = [%subst {|[ \r\n]+$|} / ""] s

let read1 ~filepath ~linenum line =
  let row = [%split {|\s+|}] line in
  if List.length row < 7 then
    failwith Fmt.(str "Row %d in file %s has fewer than seven whitespace-separated strings."
                    linenum filepath) else
  match row with
    (sample_number::structure_id::coord1::coord2::coord3::radius::parent_sample_number::_) ->
    let sample_number = int_of_string sample_number in
    let structure_id = int_of_string structure_id in
    let coord1 = float_of_string coord1 in
    let coord2 = float_of_string coord2 in
    let coord3 = float_of_string coord3 in
    let radius = float_of_string radius in
    let parent_sample_number = int_of_string parent_sample_number in
    let v = {
        sample_number
      ; structure_id
      ; coord_triple=(coord1,coord2,coord3)
      ; radius
      ; parent_sample_number
      } in
    v
  | _ ->
     failwith Fmt.(str "Malformed Row %d in file %s" linenum filepath)

let main() =
  let verbose = ref false in
  let warmup = ref 0 in
  let count = ref 1 in
  let dump = ref false in
  Arg.(parse_argv Sys.argv [
           "-dump",Set dump,"dump"
         ; "-verbose",Set verbose,"verbose"
         ; "-warmup",  Set_int warmup, "warmup"
         ; "-count",  Set_int count, "count"
         ] (fun s -> failwith "no anon args")
         "caml1: usage") ;
  let dump = !dump  in
  let verbose = !verbose  in
  let warmup = !warmup in
  let count = !count in
  Fmt.(pf stderr "verbose=%b, warmup=%d,  count=%d\n%!" verbose warmup count) ;
  let line = "201 3 594.5597 444.0379 80.8959 0.1373 200" in
  for i = 1 to  warmup do
    ignore (read1 ~filepath:"<string>" ~linenum:1 line)
  done;
  let nn = read1 ~filepath:"<string>" ~linenum:1 line in
  if dump then
    Fmt.(pf stderr "Dump: %s\n%!" (dump_node nn)) ;
  let stime = Unix.gettimeofday() in
  for i = 1 to  count do
    ignore (read1 ~filepath:"<string>" ~linenum:1 line)
  done;
  let etime = Unix.gettimeofday() in
  Fmt.(pf stderr "elapsed: %f\n%!" (etime -. stime))
;;

if not !Sys.interactive then main()
;;
