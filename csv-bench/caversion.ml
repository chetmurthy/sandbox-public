open Core
open Stdio

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

  val seq_of_swc : string -> swcline' Sequence.t
  val list_of_swc : string -> (int * swcline') list      
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

  let fhdtl_exn ell f =
    match ell with
    | x :: a -> (f x, a)
    | [] -> raise (Invalid_argument "List is empty.")

  let parse_line str =
    let ell = String.split_on_chars ~on:[' '] str
              |> List.filter ~f:(fun s -> String.length s > 0) in
    let id, t1 = fhdtl_exn ell Int.of_string in
    let nodetype, t2 = fhdtl_exn t1 Int.of_string in
    let x, t3 = fhdtl_exn t2 Float.of_string in
    let y, t4 = fhdtl_exn t3 Float.of_string in
    let z, t5 = fhdtl_exn t4 Float.of_string in
    let r, t6 = fhdtl_exn t5 Float.of_string in
    let parent_id, _ = fhdtl_exn t6
        (fun str -> let i = Int.of_string str in
          if i > 0 then Some i else None) in
    { id; nodetype; x;y;z;r; parent_id }

  (** Return a sequence of nodes. *)
  let seq_of_swc filename =
    let data = In_channel.read_lines filename in
    (* let stream = In_channel.create filename in *)
    (* let data = In_channel.input_lines stream in *)
    let dataseq = Sequence.of_list data
                  |> Sequence.filter ~f:(fun s -> not (String.is_prefix s ~prefix:"#" || String.is_empty s))
                  |> Sequence.map ~f:parse_line
    in dataseq

  let list_of_swc filename =
    let data = In_channel.read_lines filename in
    List.filter_map ~f:(
      fun s -> if String.is_prefix s ~prefix:"#" || String.is_empty s then None else
          Some (let r = parse_line s in (r.id, r))) data

end
open Read_swc
let map_of_seq seq =
  let seq' = Sequence.map seq ~f:(fun r -> (r.id, r)) in
  match Int.Map.of_sequence seq' with
  | `Ok m -> m
  | _ -> raise (Invalid_argument "Duplicate key")

let hash_of_seq seq =
  let h = Hashtbl.create ~growth_allowed:true ~size:100 (module Int) in
  let () = Sequence.iter seq ~f:(fun r -> Hashtbl.set h ~key:r.id ~data:r) in
  h
  (* let ell = Sequence.to_list_rev (Sequence.map seq ~f:(fun r -> (r.id, r))) in *)
  (* Hashtbl.of_alist_exn ~growth_allowed:true ~size:100 (module Int) ell *)
open Swc.Parse
open Swc.Batch
    
let () = print_endline "Hello, World!"
let dir = Sys.argv.(1)

(* let map_seq = map_over_dir Read_swc.seq_of_swc *)
(*         map_of_seq dir *)

(* let hashtbl_seq = map_over_dir Read_swc.list_of_swc *)
(*         (Core.Hashtbl.of_alist_exn ~growth_allowed:true ~size:100 (module Core.Int)) dir *)

let hashtbl_seq = map_over_dir Read_swc.seq_of_swc
        hash_of_seq dir

(* let () = Core.Sequence.iter map_seq ~f:(fun a -> *)
(*     match (Core.Map.min_elt a) with *)
(*     | Some (k, _)-> Printf.printf "%d\n" k *)
(*     | None -> print_endline "NULL\n") *)

let () = Core.Sequence.iter hashtbl_seq ~f:(fun a ->
    let ell = Core.Hashtbl.keys a in
    Printf.printf "%d\n" (List.hd ell))
