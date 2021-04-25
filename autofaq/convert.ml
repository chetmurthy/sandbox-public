
let unString = function
    `String s -> s
  | `Null -> "<anonymous>"
  | j -> failwith "caught"

let format1 (j : Yojson.Basic.t) =
try
  match j with
    `Assoc l ->
    let textj = List.assoc "text" l in
    let real_namej = List.assoc "real_name" l in
    Fmt.(str "%s: %s\n\n" (unString real_namej) (unString textj))
  | _ -> Fmt.(str "format1: match failed on %s" (Yojson.Basic.pretty_to_string j))
with Failure _ ->
    failwith Fmt.(str "format1: failed on %s" (Yojson.Basic.pretty_to_string j))

let convert_it n j =
  let ofname = Printf.sprintf "%d.txt" n in
  let oc = open_out ofname in
  output_string oc "=== FAQ ITEM (UNDER DEVELOPMENT) ===\n\n" ;
  begin match j with
    `Assoc l ->
    output_string oc (format1 j) ;
    let replies = List.assoc "replies" l in begin
      match replies with
        `List rl ->
        List.iter (fun j -> output_string oc (format1 j)) rl
      | _ -> failwith Fmt.(str "convert_it(replies): %s" (Yojson.Basic.pretty_to_string j))
    end
  | _ -> failwith Fmt.(str "convert_it: %s" (Yojson.Basic.pretty_to_string j))
  end ;
  close_out oc

let read1 n ic =
  let strm = Yojson.Basic.stream_from_channel ic in
  let rec convrec n =
    match Stream.next strm with
      j -> convert_it n j ;
      convrec (n+1)
    | exception Stream.Error _ -> ()
    | exception Stream.Failure -> ()
  in convrec 100

let main() =
  let n = int_of_string Sys.argv.(1) in
  Fmt.(pf stderr "converting starting at %d\n%!" n) ;
  read1 n stdin

;;

main() ;;
