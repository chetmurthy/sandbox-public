
open Async ;;

let rec readn ic n =
  if n = 0 then Deferred.return n
  else
    Deferred.bind (Reader.read_char ic)
      (function `Ok _ -> readn ic (n-1)
              | `Eof -> Deferred.return n)

let bench f n =
  let stime = Unix.gettimeofday() in
  Deferred.bind (Reader.open_file ~buf_len:4096 f)
    (fun ic -> Deferred.bind (readn ic n)
        (fun unread ->
           let etime = Unix.gettimeofday() in
           Stdlib.Printf.printf "%d read in %f secs\n%!" (n-unread) (etime -. stime) ;
           Shutdown.exit 0
        ))
;;
bench Sys.argv.(1) (int_of_string Sys.argv.(2)) ;;
Scheduler.go() ;;
