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
