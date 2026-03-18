(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** The [Status.t] type distinguishes between resolved and unresolved code review
    comments.

    - [CR]: An unresolved code review comment.
    - [XCR]: A resolved code review comment. *)
type t =
  | CR
  | XCR

val compare : t -> t -> int
val equal : t -> t -> bool
val all : t list
val to_dyn : t -> Dyn.t
val to_string : t -> string
