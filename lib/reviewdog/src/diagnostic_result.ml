(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { source : Source.t option [@yojson.default None]
  ; severity : Severity.t option [@yojson.default None]
  ; diagnostics : Diagnostic.t list
  }
[@@deriving equal, compare, yojson]
