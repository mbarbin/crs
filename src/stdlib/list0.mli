(*_**************************************************************************************)
(*_  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*_  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*_  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(*_**************************************************************************************)

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
