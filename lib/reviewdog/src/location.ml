(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { path : string
  ; range : Range.t option [@yojson.option]
  }
[@@deriving equal, compare, yojson]
