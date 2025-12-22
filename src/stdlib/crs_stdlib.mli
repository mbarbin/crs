(*_*******************************************************************************)
(*_  crs - A tool for managing code review comments embedded in source code      *)
(*_  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

module Code_error = Code_error
module Dyn = Dyn0
module Ordering = Ordering

val print_dyn : Dyn.t -> unit
val phys_equal : 'a -> 'a -> bool

module Int : sig
  include module type of struct
    include Int
  end

  val incr : t ref -> unit
  val to_dyn : t -> Dyn.t
  val to_string_hum : t -> string
end

module List : sig
  include module type of struct
    include Stdlib.ListLabels
  end

  val equal : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
  val exists : 'a t -> f:('a -> bool) -> bool
  val filter : 'a t -> f:('a -> bool) -> 'a t
  val filter_map : 'a t -> f:('a -> 'b option) -> 'b t
  val filter_mapi : 'a t -> f:(int -> 'a -> 'b option) -> 'b t
  val filter_opt : 'a option t -> 'a t
  val find : 'a list -> f:('a -> bool) -> 'a option
  val find_exn : 'a list -> f:('a -> bool) -> 'a
  val for_all : 'a t -> f:('a -> bool) -> bool
  val group : 'a t -> break:('a -> 'a -> bool) -> 'a t t
  val hd : 'a list -> 'a option
  val hd_exn : 'a list -> 'a
  val iter : 'a t -> f:('a -> unit) -> unit
  val map : 'a t -> f:('a -> 'b) -> 'b t
  val mem : 'a t -> 'a -> equal:('a -> 'a -> bool) -> bool
  val sort : 'a t -> compare:('a -> 'a -> int) -> 'a t
  val sort_and_group : 'a t -> compare:('a -> 'a -> int) -> 'a t t
  val unzip : ('a * 'b) t -> 'a t * 'b t
end

module Option : sig
  include module type of struct
    include Option
  end

  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  val iter : 'a t -> f:('a -> unit) -> unit
  val map : 'a t -> f:('a -> 'b) -> 'b t
end

module Ref : sig
  val set_temporarily : 'a ref -> 'a -> f:(unit -> 'b) -> 'b
end

module Result : sig
  include module type of struct
    include Result
  end

  val bind : ('a, 'e) t -> f:('a -> ('b, 'e) t) -> ('b, 'e) t
  val iter : ('a, _) t -> f:('a -> unit) -> unit
  val map : ('a, 'e) t -> f:('a -> 'b) -> ('b, 'e) t
end

module String : sig
  include module type of struct
    include StringLabels
  end

  val chop_prefix : t -> prefix:t -> t option
  val concat : t list -> sep:t -> t
  val is_empty : t -> bool
  val lsplit2 : t -> on:char -> (t * t) option
  val lstrip : ?drop:(char -> bool) -> t -> t
  val rstrip : ?drop:(char -> bool) -> t -> t
  val split : t -> on:char -> t list
  val split_lines : t -> t list
  val strip : t -> t
  val substr_replace_all : t -> pattern:t -> with_:t -> t
  val to_dyn : t -> Dyn.t
  val to_string : t -> t
end

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
