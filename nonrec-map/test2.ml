open Lexing
let map_position p = p

type bop = PLUS | MINUS | DIV | MUL

let rec (map_bop : bop -> bop) =
  fun arg ->
    (function
       PLUS -> PLUS
     | MINUS -> MINUS
     | DIV -> DIV
     | MUL -> MUL)
      arg

type uop = UMINUS | UPLUS

let rec (map_uop : uop -> uop) =
  fun arg ->
    (function
       UMINUS -> UMINUS
     | UPLUS -> UPLUS)
      arg

type expr =
    BINOP of position * bop * expr * expr
  | UNOP of position * uop * expr * expr
  | VAR of position * string
  | LAM of position * string * stmt list
and stmt =
    RETURN of position * expr
  | DECL of position * string * expr
  | ASSIGN of position * string * expr

type 'a dt = {
  it : 'a ;
  map_position : 'a dt -> Lexing.position -> Lexing.position ;
  map_bop : 'a dt -> bop -> bop ;
  map_uop : 'a dt -> uop -> uop ;
  map_expr : 'a dt -> expr -> expr ;
  map_stmt : 'a dt -> stmt -> stmt ;
}

let (map_expr : 'a dt -> expr -> expr) =
  fun dt arg ->
    (function
       BINOP (a_0, a_1, a_2, a_3) ->
         BINOP (dt.map_position dt a_0, dt.map_bop dt a_1, dt.map_expr dt a_2, dt.map_expr dt a_3)
     | UNOP (a_0, a_1, a_2, a_3) ->
         UNOP (dt.map_position dt a_0, dt.map_uop dt a_1, dt.map_expr dt a_2, dt.map_expr dt a_3)
     | VAR (a_0, a_1) -> VAR (dt.map_position dt a_0, (fun x -> x) a_1)
     | LAM (a_0, a_1, a_2) ->
         LAM
           (dt.map_position dt a_0, (fun x -> x) a_1,
            (fun a -> List.map (dt.map_stmt dt) a) a_2))
      arg

let (map_stmt : 'a dt -> stmt -> stmt) =
  fun dt arg ->
    (function
       RETURN (a_0, a_1) -> RETURN (dt.map_position dt a_0, dt.map_expr dt a_1)
     | DECL (a_0, a_1, a_2) ->
         DECL (dt.map_position dt a_0, (fun x -> x) a_1, dt.map_expr dt a_2)
     | ASSIGN (a_0, a_1, a_2) ->
         ASSIGN (dt.map_position dt a_0, (fun x -> x) a_1, dt.map_expr dt a_2))
      arg

