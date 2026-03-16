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
val to_dyn : t -> Dyn0.t
val to_string : t -> t
