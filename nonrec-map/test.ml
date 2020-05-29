
open Lexing
let map_position p = p
type bop = PLUS | MINUS | DIV | MUL [@@deriving map]
type uop = UMINUS | UPLUS [@@deriving map]

type expr =
    BINOP of position * bop * expr * expr
  | UNOP of position * uop * expr * expr
  | VAR of position * string
  | LAM of position * string * stmt list
and stmt =
    RETURN of position * expr
  | DECL of position * string * expr
  | ASSIGN of position * string * expr [@@deriving map]

