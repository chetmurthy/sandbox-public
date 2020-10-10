#use "topfind";;
#thread ;;
#require "lwt";;
#require "lwt.unix";;
#require "rresult";;
#require "fmt";;

open Result
open Rresult
open Rresult.R

let async_prom input =
  Lwt.bind (Lwt_unix.sleep 1.0)
    (fun () ->
       if input = 0 then Lwt.return (Ok "hello, world")
       else Lwt.return (Error (Failure "nah, brah")))

let example_prom () =
  Lwt.bind (async_prom 5)
    (function
        Ok response -> Fmt.(pf stderr "INFO got %s" response) ; Lwt.return ()
      | Error e -> Fmt.(pf stderr "WARN failed: %a" exn e); Lwt.return ())

let len_prom input =
  Lwt.bind (async_prom input)
    (fun x -> Lwt.return (R.bind x (fun response -> Ok (String.length response))))

let trace_prom name f arg =
  let before = Unix.gettimeofday() in
  Lwt.bind (f arg)
    (function
        Ok response ->
        Fmt.(pf stderr "INFO %s success in  %f\n%!" name (Unix.gettimeofday() -. before));
        Lwt.return (Ok response)
      | Error e ->
        Fmt.(pf stderr "WARN %s failure in  %f\n%!" name (Unix.gettimeofday() -. before));
        Lwt.return (Error e))

let traced_len_prom =
  trace_prom "test" async_prom
