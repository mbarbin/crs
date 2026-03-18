(*_**************************************************************************************)
(*_  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*_  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*_  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(*_**************************************************************************************)

(** A module wrapping JSON handling for use in the project.

    This provides a centralized type and functions for JSON serialization,
    abstracting over the underlying library (currently Yojson). *)

type t = Yojson.Basic.t

(** Exception raised when JSON parsing or validation fails. *)
exception Error of t * string

(** Pretty-print a JSON value to a string. *)
val to_string : t -> string
