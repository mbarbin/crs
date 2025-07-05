(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

type t =
  { source : Source.t option
  ; severity : Severity.t option
  ; diagnostics : Diagnostic.t list
  }
[@@deriving equal, compare, yojson]
