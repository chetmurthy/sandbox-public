open D2d_shared ;

value max_period = 4 ;

value matchl (patl : list char) =
  let rec mrec = fun [
        [] -> fparser [ [: :] -> () ]
      | [h::t] -> fparser [ [: `c when c = h ; rv = mrec t :] -> rv ]
      ] in
  mrec patl
;

value rec count0 pattern = fparser
  [ [: () = matchl pattern ; n = count0 pattern :] -> n+1
  | [: () = matchl pattern :] -> 1
  ]
;

value rec count pattern =
  if List.length pattern >= max_period then fparser [ ] else
  fparser
    [ [: `c ; rv = count0 (pattern @ [c]) :] -> ((pattern @ [c]), rv+1)
    | [: `c ; rv = count (pattern @ [c]) :] -> rv
    ]
;

value min_zeroes = 8 ;

(* NOTE WELL: this code blows the stack, b/c of bug
   (well, an inadequacy) in pa_fstream

value rec zrec n = fparser
    [ [: `'\000' ; rv = zrec (n+1) :] -> rv
    | [: :] -> n ]
;
 *)

value rec zrec' n fstrm =
  match Fstream.next fstrm with [
      Some ('\000', fstrm) -> zrec' (n+1) fstrm
    | _ -> Some (n, fstrm)
    ]
;

value zeroes fstrm =
  match zrec' 0 fstrm with [
      None -> assert False
    | Some (n, fstrm) as rv ->
       if n >= min_zeroes then rv else None
  ]
;

value rec convert = fparser bp
  [ [: n=zeroes ; l = convert :] -> [ (bp, ZEROES n) :: l ]
  | [: (pat,n) = count [] ; l = convert :] -> [ (bp, REPEAT pat n) :: l ]
  | [: `c ; l = convert :] -> [ (bp, CHAR c) :: l ]
  | [: :] -> []
  ]
;

value convert_fmt fstrm =
  match convert fstrm with [
      None -> assert False
    | Some (l, _) ->
       Fmt.(pf stdout "%a\n%!" (list ~{sep=sp} fmt_result) l)
  ]
;

