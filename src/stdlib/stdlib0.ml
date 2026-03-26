(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

module Absolute_path = Absolute_path0
module Char = Char0
module Code_error = Code_error
module Dyn = Dyn0
module Err = Err0
module Fpath = Fpath0
module Fsegment = Fsegment0
module Int = Int0
module Loc = Loc0
module Json = Json
module List = List0
module Option = Option0
module Ordering = Ordering
module Pp = Pp0
module Pp_tty = Pp_tty0
module Ref = Ref0
module Relative_path = Relative_path0
module Result = Result0
module String = String0

let print pp = Format.printf "%a@." Pp.to_fmt pp
let print_dyn dyn = print (Dyn.pp dyn)
let phys_equal a b = a == b
let require cond = if not cond then failwith "Required condition does not hold."

let require_does_raise f =
  match f () with
  | _ -> Code_error.raise "Did not raise." []
  | exception e -> print_endline (Printexc.to_string e)
;;

module With_equal_and_dyn = struct
  module type S = sig
    type t

    val equal : t -> t -> bool
    val to_dyn : t -> Dyn.t
  end
end

let require_equal
      (type a)
      (module M : With_equal_and_dyn.S with type t = a)
      (v1 : a)
      (v2 : a)
  =
  if not (M.equal v1 v2)
  then
    Code_error.raise
      "Values are not equal."
      [ "v1", v1 |> M.to_dyn; "v2", v2 |> M.to_dyn ]
;;

let require_not_equal
      (type a)
      (module M : With_equal_and_dyn.S with type t = a)
      (v1 : a)
      (v2 : a)
  =
  if M.equal v1 v2
  then
    Code_error.raise "Values are  equal." [ "v1", v1 |> M.to_dyn; "v2", v2 |> M.to_dyn ]
;;

let print_endline = Stdlib.print_endline
