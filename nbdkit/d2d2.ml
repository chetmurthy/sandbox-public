open D2d_shared ;

module Buf = struct

value read_fully fname =
  fname |> Fpath.v |> Bos.OS.File.read |> Rresult.R.get_ok
;

value pos (ofs, _) = ofs ;
value size (ofs, buf) = String.length buf - ofs ;

value of_string ?{ofs=0} s = (ofs, s) ;
value of_file ?{ofs=0} s = (ofs, read_fully s) ;

value abs_get (_, buf) i = String.get buf i ;
value abs_sub (_, buf) i len = String.sub buf i len ;

end
;

value max_period = 8 ;

type patt = { len : int ; two : Pcre.regexp ; all : Pcre.regexp } ;

value one = { len = 1 ; two = Pcre.regexp "(.)\1" ; all = Pcre.regexp "(.)\1+" } ;
value two = { len = 2 ; two = Pcre.regexp "(..)\1" ; all = Pcre.regexp "(..)\1+" } ;
value three = { len = 3 ; two = Pcre.regexp "(...)\1" ; all = Pcre.regexp "(...)\1+" } ;
value four = { len = 4 ; two = Pcre.regexp "(....)\1" ; all = Pcre.regexp "(....)\1+" } ;
value five = { len = 5 ; two = Pcre.regexp "(.....)\1" ; all = Pcre.regexp "(.....)\1+" } ;
value six = { len = 6 ; two = Pcre.regexp "(......)\1" ; all = Pcre.regexp "(......)\1+" } ;
value seven = { len = 7 ; two = Pcre.regexp "(.......)\1" ; all = Pcre.regexp "(.......)\1+" } ;
value eight = { len = 8 ; two = Pcre.regexp "(........)\1" ; all = Pcre.regexp "(........)\1+" } ;

value all = [one; two; three; four; five; six; seven; eight] ;

value match0 ?{flags=[`ANCHORED]} rex (ofs, buf) =
  match Pcre.exec ~{rex=rex} ~{pos=ofs} ~{flags=flags} buf with [
      ss ->
      let (bp,ep) = Pcre.get_substring_ofs ss 0 in do {
        assert (bp = ofs) ;
        Some (ss, (ep, buf))
      }
    | exception Not_found -> None
  ]
;

value match1 ?{flags=[`ANCHORED]} rex (ofs, buf) =
  match Pcre.exec ~{rex=rex} ~{pos=ofs} ~{flags=flags} buf with [
      ss ->
      let (bp,ep) = Pcre.get_substring_ofs ss 0 in
      let pattern = Pcre.get_substring ss 1 in
      let patlen = String.length pattern in
      let nreps = (ep-bp) / patlen in
      do {
        assert (bp = ofs) ;
        Some (pattern, nreps, (ep, buf))
      }
    | exception Not_found -> None
  ]
;

value interval n m = 
  let rec interval_n (l,m) =
    if n > m then l else interval_n ([m::l],pred m)
  in interval_n ([],m)
;

value range = interval 1 ;

value zeroes = Pcre.regexp "\\x00+" ;

value mkpat n = Printf.sprintf "(?:(%s)\\g{-1}+)" (String.make n '.') ;

value all_pat =
  let z = "(?:(\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00)\\x00*)" in
  let c = "(.)" in
  let pats = List.map mkpat (range max_period) in
  String.concat "|" [z :: (pats @ [c])]
;
value all_re = Pcre.regexp all_pat ;

value all_substrings ss =
  let n = Pcre.num_of_subs ss in
  let get1 n =
    match Pcre.get_substring ss n with [
        x -> Some x
      | exception Not_found -> None
      | exception Invalid_argument _ -> failwith (Printf.sprintf "all_substrings: %d not valid" n)
      ] in
  let subs = (interval 0 (n-1)) |> List.map get1 in
  subs
;

value all_substrings_ofs ss =
  let n = Pcre.num_of_subs ss in
  let get1 n =
    match Pcre.get_substring_ofs ss n with [
        x -> Some x
      | exception Not_found -> None
      | exception Invalid_argument _ -> failwith (Printf.sprintf "all_substrings: %d not valid" n)
      ] in
  let subs = (interval 0 (n-1)) |> List.map get1 in
  subs
;

value filter p =
  let rec filter_aux = fun [
      [] -> []
    | [x::l] -> if p x then [x::filter_aux l] else filter_aux l ]
  in filter_aux
;

value count p l = List.length (filter p l) ;

value isSome = fun [ Some _ -> True | None -> False ] ;

value collapse_substrings_ofs l = do {
    assert (List.length l = 3 + max_period) ;
    assert (isSome (List.hd l)) ;
    assert (1 = count isSome (List.tl l)) ;
    let (bp, ep) = match List.hd l with [
          Some (bp,ep) -> (bp, ep)
        | None -> assert False
        ] in
    let (i, v) = match List.find_map (fun [ (i, Some v) -> Some(i, v) | _ -> None]) (List.mapi (fun n v -> (n, v)) (List.tl l)) with [
      Some (i, v) -> (i,v) | None -> assert False
    ] in
    ((bp, ep), (i,v))
  }
;

value step buf =
  match match0 all_re buf with [
    None -> do {
      assert (Buf.size buf = 0) ;
      None
    }
  | Some (ss, buf) ->
      let ofsl = all_substrings_ofs ss in do {
        assert (List.length ofsl = 3 + max_period) ;
        Some (collapse_substrings_ofs ofsl, buf)
      }
  ]
;

value explode_chars s =
    let slen = String.length s in
    let rec aux n = if n < slen then [ (String.get s n)::(aux (n+1)) ] else [] in
        aux 0
;

value convert buf =
  let rec crec buf =
    match step buf with [
      Some (((bp, ep), (i, (pbp, pep))), buf) ->
      if i = 0 then
        let len = ep - bp in
        [ (bp, ZEROES len) :: crec buf ]
      else if i = 1+max_period then
        let c = Buf.abs_get buf bp in
        [ (bp, CHAR c) :: crec buf ]
      else do {
        let plen = pep - pbp in
        assert (plen = i) ;
        let nreps = (ep-bp) / plen in
        assert (nreps * plen = (ep - bp)) ;
        let cl = explode_chars (Buf.abs_sub buf pbp plen) in
        [ (bp, REPEAT cl nreps) :: crec buf ]
      }
    | None -> []
  ] in
  crec buf
;

value convert_fmt buf =
  let l = convert buf in
  Fmt.(pf stdout "%a\n%!" (list ~{sep=sp} fmt_result) l)
;
