(*_**************************************************************************************)
(*_  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*_  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*_  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(*_**************************************************************************************)

(** Extending [Stdlib] for use in the project. *)

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

val print_dyn : Dyn.t -> unit
val phys_equal : 'a -> 'a -> bool
val require : bool -> unit
val require_does_raise : (unit -> 'a) -> unit

module With_equal_and_dyn : sig
  module type S = sig
    type t

    val equal : t -> t -> bool
    val to_dyn : t -> Dyn.t
  end
end

val require_equal : (module With_equal_and_dyn.S with type t = 'a) -> 'a -> 'a -> unit
val require_not_equal : (module With_equal_and_dyn.S with type t = 'a) -> 'a -> 'a -> unit

(** Transition dependencies *)

(** Used to silence base warning. *)
val print_endline : string -> unit
