(* camlp5o *)
(* pa_fsm.ml,v *)
(* Copyright (c) INRIA 2007-2017 *)

open Pa_ppx_base
open Pa_passthru
open Ppxutil
open Toy

let quotify loc =
  let qbinop = function
      Plus -> <:expr< Plus >>
    | Minus -> <:expr< Minus >>
    | Mult -> <:expr< Mult >>
    | Div -> <:expr< Div >> in
  let rec qrec = function
      EConst n -> <:expr< EConst $int:string_of_int n$ >>
    | EVar s -> <:expr< EVar $str:String.escaped s$ >>
    | EBinop (bop, e1, e2) -> <:expr< EBinop $qbinop bop$ $qrec e1$ $qrec e2$ >>
  in
  qrec

let rewrite_expr arg = function
  <:expr:< [%fsm $str:s$ ;] >> ->
  Toy.(s |> parse_expr |> quotify loc)
| _ -> assert false


let install () = 
let ef = EF.mk () in 
let ef = EF.{ (ef) with
            expr = extfun ef.expr with [
    <:expr:< [%fsm $str:s$ ;] >> as z ->
    fun arg fallback ->
      Some (rewrite_expr arg z)
  ] } in
  Pa_passthru.(install { name = "pa_fsm"; ef =  ef ; pass = None ; before = [] ; after = [] })
;;

install();;
