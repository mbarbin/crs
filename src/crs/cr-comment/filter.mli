(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** A type to select only a subset of CRs. *)

type t =
  | All
  | Invalid
  | CRs
  | XCRs
  | Now
  | Soon
  | Someday

val compare : t -> t -> int
val equal : t -> t -> bool
val all : t list
val to_dyn : t -> Dyn.t

(** {1 Representation} *)

(** A lowercase version of [t] for use e.g. as command line flags. *)
val to_string : t -> string

(** This defines opinionated shorthands to designate each case, to be used in
    UIs. May be shared by cli, editor integration, etc. *)
val shorthand : t -> char

(** {1 Matching} *)

(** Returns [true] iif the filter applies to the supplied CR. *)
val matches : t -> cr:Cr_comment0.t -> bool
