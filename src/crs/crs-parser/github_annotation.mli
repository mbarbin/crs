(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

(** GitHub Annotations are created when encountering special log lines produced
    by actions during workflow executions.

    Examples:

    {v
     ::notice file={name},line={line},endLine={endLine},title={title}::{message}
     ::warning file={name},line={line},endLine={endLine},title={title}::{message}
    v}

    This module allow creating and producing workflow commands that can create
    annotations. *)

module Severity : sig
  type t =
    | Error
    | Warning
    | Notice

  val to_dyn : t -> Dyn.t
end

type t

val to_dyn : t -> Dyn.t
val create : loc:Loc.t -> severity:Severity.t -> title:string -> message:string -> t

(** {1 Serialize} *)

(** Create the syntax to be produced by log lines, without the trailing "\n". *)
val to_string : t -> string
