(*_*******************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code    *)
(*_  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*_                                                                              *)
(*_  This file is part of crs.                                                   *)
(*_                                                                              *)
(*_  crs is free software; you can redistribute it and/or modify it under the    *)
(*_  terms of the GNU Lesser General Public License as published by the Free     *)
(*_  Software Foundation either version 3 of the License, or any later version,  *)
(*_  with the LGPL-3.0 Linking Exception.                                        *)
(*_                                                                              *)
(*_  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*_  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*_  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*_  the file `NOTICE.md` at the root of this repository for more details.       *)
(*_                                                                              *)
(*_  You should have received a copy of the GNU Lesser General Public License    *)
(*_  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*_  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(*_*******************************************************************************)

(** Extending [Stdlib] for use in the project. *)

module Char = Char0
module Code_error = Code_error
module Dyn = Dyn0
module Int = Int0
module Json = Json
module List = List0
module Option = Option0
module Ordering = Ordering
module Ref = Ref0
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
