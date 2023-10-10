module Read_swc : sig
  type swcline' =
  { id : int;
    nodetype : int;
    x : float;
    y : float;
    z : float;
    r : float;
    parent_id : int option
  }

  val read_file : string -> (int, swcline') Hashtbl.t
end =
struct
  type swcline' =
    { id : int;
      nodetype : int;
      x : float;
      y : float;
      z : float;
      r : float;
      parent_id : int option
    }

  let read_file filename =
    let tbl = Hashtbl.create 100 in
    let ic = Scanf.Scanning.open_in filename in
    try
      while true do
        (* Test for comment *)
        let is_comment = Scanf.bscanf ic "%0c" (function '#' -> true | _ -> false) in
        if is_comment then
          Scanf.bscanf ic "#%s@\n" (fun _line -> ())
        else
          Scanf.bscanf ic " %d %d %f %f %f %f %d \n"
            (fun id nodetype x y z r parent ->
               let parent_id = if parent > 0 then Some parent else None in
               let node = { id; nodetype; x;y;z;r; parent_id } in
               Hashtbl.add tbl id node)
      done;
      assert false
    with End_of_file -> Scanf.Scanning.close_in ic; tbl
       | exn -> Scanf.Scanning.close_in ic; raise exn
end

open Swc.Parse
open Swc.Batch

let () = print_endline "Hello, World!"
let dir = Sys.argv.(1)


let hashtbl_seq = map_over_dir Read_swc.read_file
        Fun.id dir

let () = Core.Sequence.iter hashtbl_seq ~f:(fun a ->
    let ell = Hashtbl.to_seq_keys a in
    match Seq.uncons ell with
    | None -> failwith "Empty table"
    | Some (id, _) ->
       Printf.printf "%d\n" id)

