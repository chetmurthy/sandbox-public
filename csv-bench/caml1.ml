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

let read_swc_node_dict ~filepath =
  let ic = open_in filepath in
  let h = Hashtbl.create 23 in
  let linenum = ref 0 in
  try while true do
        let line = input_line ic in
        incr linenum ;
        let line = strip line in
        if String.get line 0 = '#' || String.length line < 2 then () else
        let v = read1 ~filepath ~linenum:!linenum line in
        Hashtbl.add h v.sample_number v
      done ;
      close_in ic ;
      h ;
  with End_of_file -> close_in ic ; h
     | e ->
        close_in ic ;
        Fmt.(pf stderr "read_swc_node_dict: error: %a" exn e) ;
        raise e

let main() =
  let filename = ref "" in
  let verbose = ref false in
  let warmup = ref 0 in
  let count = ref 1 in
  let dump = ref (-1) in
  Arg.(parse_argv Sys.argv [
           "-verbose",Set verbose,"verbose"
         ; "-warmup",  Set_int warmup, "warmup"
         ; "-count",  Set_int count, "count"
         ; "-dump",  Set_int dump, "dump"
         ] (fun s -> filename := s)
         "caml1: usage") ;
  let filename = !filename in
  let verbose = !verbose  in
  let warmup = !warmup in
  let count = !count in
  Fmt.(pf stderr "filename=%s, verbose=%b, warmup=%d,  count=%d\n%!" filename verbose warmup count) ;
  for i = 1 to  warmup do
    ignore (read_swc_node_dict ~filepath:filename)
  done;
  let d = read_swc_node_dict ~filepath:filename in
  Fmt.(pf stderr "# entries: %d\n%!" (Hashtbl.length d)) ;
  if !dump <> -1 then
    Fmt.(pf stderr "Dump: %s\n%!" (dump_node (Hashtbl.find d !dump))) ;
  let stime = Unix.gettimeofday() in
  for i = 1 to  count do
    ignore (read_swc_node_dict ~filepath:filename)
  done;
  let etime = Unix.gettimeofday() in
  Fmt.(pf stderr "elapsed: %f\n%!" (etime -. stime))
;;

if not !Sys.interactive then main()
;;
