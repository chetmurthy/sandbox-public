
let list_of_stream strm =
  let rec lrec acc = parser
    [< 'e ; strm >] -> lrec (e::acc) strm
  | [< >] -> List.rev acc
  in
  lrec [] strm

 type t = 
  EConst of int
| EVar of string
| EBinop of binop * t * t
and binop = Plus | Minus | Mult | Div

let keywords = [ "+";  "-";  "*";  "/"; "("; ")"]

let mk_binary_minus s = s |> String.split_on_char '-' |> String.concat " - "
                      
let lexer s = s |> mk_binary_minus |> Stream.of_string |> Genlex.make_lexer keywords 

open Genlex
   
let rec p_exp0 s =
  match Stream.next s with
    | Int n -> EConst n
    | Ident i -> EVar i
    | Kwd "(" ->
       let e = p_exp s in
       begin match Stream.peek s with
       | Some (Kwd ")") -> Stream.junk s; e
       | _ -> raise Stream.Failure
       end
    | _ -> raise Stream.Failure

and p_exp1 s =
  let e1 = p_exp0 s in
  p_exp2 e1 s
  
and p_exp2 e1 s =
  match Stream.peek s with
  | Some (Kwd "*") -> Stream.junk s; let e2 = p_exp1 s in EBinop(Mult, e1, e2)
  | Some (Kwd "/") -> Stream.junk s; let e2 = p_exp1 s in EBinop(Div, e1, e2)
  | _ -> e1
  
and p_exp s =
  let e1 = p_exp1 s in p_exp3 e1 s
                     
and p_exp3 e1 s =
  match Stream.peek s with
  | Some (Kwd "+") -> Stream.junk s; let e2 = p_exp s in EBinop(Plus, e1, e2)
  | Some (Kwd "-") -> Stream.junk s; let e2 = p_exp s in EBinop(Minus, e1, e2)
  | _ -> e1

let parse_expr s = s |> lexer |> p_exp

