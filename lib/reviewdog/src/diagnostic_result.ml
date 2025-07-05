(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { source : Source.t option [@yojson.option]
  ; severity : Severity.t option [@yojson.option]
  ; diagnostics : Diagnostic.t list
  }
[@@deriving equal, compare, yojson]
