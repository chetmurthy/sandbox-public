#load "pa_extend.cmo";

open Sexplib.Sexp ;

  value g = Grammar.gcreate (Plexer.gmake ());
  value expr = Grammar.Entry.create g "expr";

  EXTEND
    expr:
      [ "add" LEFTA
        [ (sexp_x, x) = SELF; "-"; (sexp_y, y) = SELF -> (List[sexp_x; Atom"-"; sexp_y], x -. y)
        | (sexp_x, x) = SELF; "+"; (sexp_y, y) = SELF -> (List[sexp_x; Atom"+"; sexp_y], x -. y)
        ]
      | "mul" LEFTA
        [ (sexp_x, x) = SELF; "*"; (sexp_y, y) = SELF -> (List[sexp_x; Atom"*"; sexp_y], x *. y)
        | (sexp_x, x) = SELF; "/"; (sexp_y, y) = SELF -> (List[sexp_x; Atom"/"; sexp_y], x /. y)
        ]
      | "power" RIGHTA
        [ (sexp_x, x) = SELF; "**"; (sexp_y, y) = SELF -> (List[sexp_x; Atom"**"; sexp_y], x ** y) ]
      | "simple"
        [ "("; (sexp_x, x) = SELF; ")" -> (List[Atom "("; sexp_x; Atom ")"], x)
        | x = INT -> (Atom x, float_of_string x) ] ]
    ;
  END
;
  open Printf;

  for i = 1 to Array.length Sys.argv - 1 do {
    let (sexp_r, r) = Grammar.Entry.parse expr (Stream.of_string Sys.argv.(i)) in
    Format.printf "%s: %a -> %f\n" Sys.argv.(i) pp_hum sexp_r r;
    flush stdout;
  };
