open Toy
let x = [%fsm {| 1 + 2 - x |}]
;;
Printf.printf "%d\n" (Toy.eval ["x",5] x)
;;
