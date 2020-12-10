open Rresult ;;
open Rresult.R ;;

let rec readn ic n =
  if n = 0 then return n
  else
    bind (return (input_char ic))
      (fun _ -> readn ic (n-1))

let bench f n =
  let stime = Unix.gettimeofday() in
  bind (return (open_in f))
    (fun ic ->
       bind (readn ic n)
         (fun unread ->
           let etime = Unix.gettimeofday() in
           Stdlib.Printf.printf "%d read in %f secs\n%!" (n-unread) (etime -. stime) ;
           return ()
         )
    )
;;

bench Sys.argv.(1) (int_of_string Sys.argv.(2)) ;;
