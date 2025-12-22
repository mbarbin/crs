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
