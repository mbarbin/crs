(*_***************************************************************************)
(*_  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*_  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: MIT                                            *)
(*_***************************************************************************)

type t =
  { range : Range.t
  ; text : string
  }
[@@deriving equal, compare, yojson]
