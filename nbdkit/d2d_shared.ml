
type result_t = [
    ZEROES of int
  | REPEAT of list char and int
  | CHAR of char
  ]
;

(*
value onechar pps c = Fmt.(pf pps "0x%02x" (Char.code c)) ;
 *)
value onechar pps c = Fmt.(pf pps "%d" (Char.code c)) ;

value fmt_result pps = fun [
  (ofs, ZEROES n) -> Fmt.(pf pps "@0x%x" (ofs+n))
| (_, REPEAT [c] n) -> Fmt.(pf pps "%a*%d" onechar c n)
| (_, REPEAT l n) -> Fmt.(pf pps "(%a)*%d" (list ~{sep=const string " "} onechar) l n)
| (_, CHAR c) -> Fmt.(pf pps "%a" onechar c)
]
;

