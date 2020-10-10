#use "topfind";;
#require "rresult";;
#require "fmt";;
#require "unix";;

module type CSIG = sig
  type ans
  type 'a cont = 'a -> ans
  type 'a comp = 'a cont -> ans
  val ikont : 'a cont
  val bind : 'a comp -> ('a -> 'b comp) -> 'b comp
  val return : 'a -> 'a comp
  val top : 'a comp -> ans
end

module Computations : CSIG = struct
  type ans = unit
  type 'a cont = 'a -> ans
  type 'a comp = 'a cont -> ans
  let ikont _ = ()

  let bind _M _f k =
    _M (fun v -> _f v k)
  let return v k = k v
  let top f = f ikont
end

module C = Computations

(*
    def callAsyncCB(input: Int, onSuccess: String => Unit, onFailure: Throwable => Unit): Unit = ???
    def callAsyncFuture(input: Int): Future[String] = ???
*)

open Result
open Rresult
open Rresult.R

let async_cb (input : int) (kont : (string, exn) R.t C.cont) =
  Unix.sleep 1 ;
  if input = 0 then kont (Ok "hello, world")
  else kont (Error (Failure "nah, brah"))

(*
    def exampleCB(): Unit =
      callAsyncCB(
        input = 5,
        onSuccess = response => logger.info(s"got $response"),
        onFailure = exception => logger.warn(s"failed: ", exception))
*)

let example_cb () kont =
  async_cb 5
    (function
        Ok response -> Fmt.(pf stderr "INFO got %s" response) ; kont ()
      | Error e -> Fmt.(pf stderr "WARN failed: %a" exn e); kont ())

(*
    def lenCB(input: Int, onSuccess: Int => Unit, onFailure: Throwable => Unit): Unit =
      callAsyncCB(input = input, onSuccess = response => onSuccess(response.length), onFailure = onFailure)
*)

let len_cb input =
  C.bind (async_cb input)
    (fun x -> C.return (R.bind x (fun response -> Ok (String.length response))))

(*
    def traceCB[T](name: String, onSuccess: T => Unit, onFailure: Throwable => Unit)(
        f: ((T => Unit), (Throwable => Unit)) => Unit): Unit = {
      val before = System.currentTimeMillis()
      f(value => {
        logger.info(s"$name success in ${System.currentTimeMillis() - before}ms")
        onSuccess(value)
      }, exception => {
        logger.warn(s"$name failure in ${System.currentTimeMillis() - before}ms: ", exception)
        onFailure(exception)
      })
    }
*)

let trace_cb name f arg =
  let before = Unix.gettimeofday() in
  C.bind (f arg)
    (function
        Ok response ->
        Fmt.(pf stderr "INFO %s success in  %f\n%!" name (Unix.gettimeofday() -. before));
        C.return (Ok response)
      | Error e ->
        Fmt.(pf stderr "WARN %s failure in  %f\n%!" name (Unix.gettimeofday() -. before));
        C.return (Error e))
(*

    def tracedLenCB(input: Int, onSuccess: Int => Unit, onFailure: Throwable => Unit): Unit =
      traceCB[String]("test", onSuccess = response => onSuccess(response.length), onFailure) {
        case (onSuccess, onFailure) =>
          callAsyncCB(input, onSuccess, onFailure)
      }
*)

let traced_len_cb =
  trace_cb "test" async_cb
