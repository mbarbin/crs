(*_**************************************************************************************)
(*_  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*_  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*_  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(*_**************************************************************************************)

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
